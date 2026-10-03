const RELEASE_MONITORING_URL = "https://release-monitoring.org/api/v2/versions/"
const CPE_SEARCH_URL = "https://cpe-guesser.cve-search.org/search"
const CPE_COMMON_PREFIX = "cpe:2.3:a:"
export const AOS_REPO_PATH = path self | path dirname | path dirname

use std null-device

# Check AerynOS package is latest in recipes repo.
export def checkupdate [
  ...packages: string@package_list_strict # Package name(s) to check
  --no-color (-C) # Don't color the status ouptut
]: nothing -> table {

  if ($packages | is-empty) {
    print "Warning: No paramaters passed, using current directory name. Pass --help to see usage"
    pwd | path basename
  } else {
    $packages
  }
  | par-each {|package|
    (
      $AOS_REPO_PATH
      | path join ($package | split chars | first) $package
    )
    | if (not ($in | path exists)) {
      error make -u {msg: $"Couldn't find recipe dir for package '($package)'" help: "There is autocomplete for existing packages you know..."}
    } else {
      $in
    }
    | (
      cd $in;
      try {open stone.yaml | select name version} catch {
        error make -u {msg: $"Couldn't find stone.yaml or it's name and version fields for package '($package)'"}
      }
      | str trim -c "'" | str trim -c '"'
      | rename -c {version: current_version}
      | update current_version {into string}
      | insert available_version (
        http get (
          $RELEASE_MONITORING_URL
          | url parse
          | update params {
            project_id: (
              try {open monitoring.yaml | get releases.id} catch {
                error make -u {msg: $"Couldn't find monitoring.yaml or it's releases.id field for package '($package)'"}
              }
            )
          }
          | url join
        )
        | get stable_versions.0
        | str trim -c "'" | str trim -c '"' # Strip any quotes
        | str replace _ . # Replace any underscores with dots
      )
      | insert status {
        |row| if ($row.current_version == $row.available_version) {
          $"(if (not $no_color) {ansi green})Already using the latest version(ansi reset)"
        } else {
          $"(if (not $no_color) {ansi red_bold})Update available(ansi reset)"
        }
      }
    )
  }
}

# Primitive CPE search tool
export def cpesearch [
  ...packages: string@package_list # Package name(s) to search for
]: nothing -> table {
  if ($packages | is-empty) {
    print "Warning: No paramaters passed, using current directory name. Pass --help to see usage"
    pwd | path basename
  } else {
    $packages
  }
  | each {|package|
    http post --content-type application/json $CPE_SEARCH_URL ({query: [$package]})
    | each {|cpe_result|
      [[cpe_id]; [$cpe_result.0]]
      | merge (
        $cpe_result.1
        | str replace $CPE_COMMON_PREFIX ''
        | split column : -n 2
        | rename vendor product
      )
      | insert cve_link {|row|
        $"https://cve.circl.lu/search?vendor=($row.vendor)&product=($row.product)"
        | ansi link
      }
    }
    | flatten
    | $in | insert name $package
  }
  | flatten
  | group-by --to-table name
  | update items {reject name}
  | rename -c {items: results}
  | do {|table,packages|
    let empty_names = $packages | where {not ($in in $table.name)}
    $empty_names | reduce -f $table {|it, acc| $acc | append {name: $it}}
  } $in $packages
}

# Go to the root directory of the AerynOS recipes
export def --env gotoaosrepo []: nothing -> nothing {cd $AOS_REPO_PATH}

# Deprecated! Use `gotoaosrepo`
export alias gotoserpentrepo = gotoaosrepo

# Go to the root of current git repository
export def --env goroot []: nothing -> nothing {
  try {
    cd (git rev-parse --show-toplevel e> (null-device))
  } catch {
    error make -u {msg: $"Seems like you are not in a git repository"}
  }
}

# Push into a package directory
export def --env chpkg [
  package: string@package_list # Package name
]: nothing -> nothing {
  try {
    cd ($AOS_REPO_PATH | path join ($package | split chars | first) $package)
  } catch {
    error make -u {msg: $"Couldn't find recipe for package ($package)" help: "There is autocomplete for existing packages you know..."}
  }
}

def package_list [
  --strict (-s) # Only return packages with monitoring and stone yaml files
]: nothing -> table {
  ls ($"($AOS_REPO_PATH)/?/*" | into glob)
  | where type == dir
  | where {
    (not $strict) or (($in.name | path join monitoring.yaml) | path exists) and (($in.name | path join stone.yaml) | path exists)
  }
  | select name
  | rename -c {name: value}
  | insert description {|row|
    try { # Provide empty description if stone.yaml or it's summary field is missing
      open ($row.value | path join stone.yaml)
      | get summary
    } catch { $"(ansi purple_bold)Missing (ansi s)stone.yaml(ansi rst_s) or (ansi s)summary(ansi rst_s) field!(ansi reset)" }
  }
  | update value {path basename}
}

 # Completer assignment (for checkupdate) neither support passing flags, nor aliases (as of nushell 0.109), which needs -s (strict) package_list function
def package_list_strict []: nothing -> table {
  package_list -s
}
