#!/bin/bash

programname=$0
function usage {
    echo ""
    echo "Read 4 layers of configuration from an App Configuration Service to produce a complete appsettings.json"
    echo "* Global/cross-application configuration for all environments"
    echo "* Global/cross-application configuration for specified environment"
    echo "* App-specific configuration for all environments"
    echo "* App-specific configuration for specified environment"
    echo ""
    echo "Assumes that labels in the App Configuration Service correspond to environment names (Ex: dev, staging, prod)"
    echo "Assumes that keys of App Configuration Service are segregated per app/service using a key prefix that should "
    echo "be trimmed when the keys are read."
    echo ""
    echo "usage: bash $programname --env string --app_cfg_prefix string --global_cfg_prefix string --app_cfg string [--app_cfg_sub string]"
    echo ""
    echo "  --env string                 Used as label in App Configuration Service"
    echo "                                   (example: dev)"
    echo "  --app_cfg_prefix string     App Configuration Service key prefix to read for app specific config"
    echo "                                   (example: myapp123:)"    
    echo "  --global_cfg_prefix string  App Configuration Service key prefix to read for global config"
    echo "                                   (example: global:)"
    echo "  --app_cfg string            App Configuration Service Name or Id"
    echo "                                   (example: appConfig-xyz)"
    echo "  --app_cfg_sub string        (Optional)App Configuration Service subscription"
    echo "                                   (example: ""My Global Subscription A"")"
    echo ""
}

while [ $# -gt 0 ]; do
    if [[ $1 == "--help" ]]; then
        usage
        exit 0
    elif [[ $1 == "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $env ]]; then
    usage
    die "Missing parameter --env"
elif [[ -z $app_cfg ]]; then
    usage
    die "Missing parameter --app_cfg"
elif [[ -z $app_cfg_prefix ]]; then
    usage
    die "Missing parameter --app_cfg_prefix"
elif [[ -z $global_cfg_prefix ]]; then
    usage
    die "Missing parameter --global_cfg_prefix"
fi

# --debug arg can be used to diagnose App Configuration Service connection issues

echo {} > appsettings_global_allenv.json 
echo {} > appsettings_global_$env.json 
echo {} > appsettings_allenv.json 
echo {} > appsettings_$env.json

common_args=( -d file --format json --name $app_cfg --separator : --skip-features --resolve-keyvault --yes )

if [[ -n $app_cfg_sub ]]; then
    common_args+=( --subscription "$app_cfg_sub" )
fi

az appconfig kv export --path appsettings_global_allenv.json --prefix "$global_cfg_prefix"  --key "$global_cfg_prefix*" "${common_args[@]}"

az appconfig kv export --path appsettings_global_$env.json --label $env --prefix "$global_cfg_prefix"  --key "$global_cfg_prefix*" "${common_args[@]}"

az appconfig kv export --path appsettings_allenv.json --prefix "$app_cfg_prefix"  --key "$app_cfg_prefix*" --skip-features "${common_args[@]}"

az appconfig kv export --path appsettings_$env.json --label $env --prefix "$app_cfg_prefix"  --key "$app_cfg_prefix*" "${common_args[@]}"

jq -s '.[0] * .[1] * .[2] * .[3]' appsettings_global_allenv.json appsettings_global_$env.json appsettings_allenv.json appsettings_$env.json > appsettings.json

# Untested Example: Generate local.settings.json for an Azure Function
# jq -s ' { Values: .[0] } + {IsEncrypted:false, Host:{CORS:"*"} }' appsettings.json > local.settings.json