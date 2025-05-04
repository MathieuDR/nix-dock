{...}: {
  mkSubdomain = domain: subdomain: "${subdomain}.${domain}";
  mkSubdomains = domain: subdomains: map (sub: "${sub}.${domain}") subdomains;
}
