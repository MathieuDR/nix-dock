{
  lib,
  PII,
  ...
}: let
  mkCommaFeedWidget = {
    title ? "Tech feeds",
    url ? lib.strings.concatImapStrings ["https://feed." PII.domain "/rest/category/entries"],
    categoryId ? "9",
    limit ? 10,
    additionalParams ? ["readType=unread"],
    cache ? "1m",
    tokenPlaceholder ? "__COMMAFEED_TOKEN__",
    feedsByLabel ? {
      "Elixir" = {
        color = "#cba6f7";
        feedIds = ["73" "71" "1002" "72" "70"];
      };
      "General" = {
        color = "#89dceb";
        feedIds = ["1003" "1005"];
      };
      "AI" = {
        color = "#cba6f7";
        feedIds = ["2002"];
      };
      "News" = {
        color = "#f38ba8";
        feedIds = ["3004" "3006" "3002" "3003" "69"];
      };
    },
  }: let
    # Create a lookup function for each feed that uses the grouped labels
    labelLookupContent = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        labelName: labelInfo:
          lib.concatMapStrings (
            feedId: "{{ if eq $feedId \"${feedId}\" }}{{ $feedLabel = \"${labelName}\" }}{{ $feedColor = \"${labelInfo.color}\" }}{{ end }}"
          )
          labelInfo.feedIds
      )
      feedsByLabel
    );

    # Build the query string from the separate parameters
    baseQuery = "id=${categoryId}&limit=${toString limit}";
    additionalQueryString = lib.concatStringsSep "&" additionalParams;
    queryString =
      if additionalQueryString == ""
      then baseQuery
      else "${baseQuery}&${additionalQueryString}";

    fullUrl = "${url}?${queryString}";

    widget = {
      type = "custom-api";
      inherit title cache;
      url = fullUrl;
      headers = {
        Authorization = "Basic ${tokenPlaceholder}";
        Accept = "application/json";
      };
      template = ''
        <ul class="list list-gap-20">
          {{ range .JSON.Array "entries" }}
            {{ $entryId := .String "id" }}
            {{ $feedId := .String "feedId" }}
            {{ $feedName := .String "feedName" }}
            {{ $starred := .Bool "starred" }}
            {{ $feedLabel := "" }}
            {{ $feedColor := "#cdd6f4" }}
            {{ $date := .Int "date" }}

            ${labelLookupContent}

            <li class="padding-block-5 rounded-sm" data-entry-id="{{ $entryId }}">
              <div style="position:relative" class="flex items-start gap-5">
                <div class="flex-grow page-column-full">
                  <div class="flex justify-between items-center">
                    <a target="_blank" href="{{ .String "url" }}" class="color-highlight size-h4 block flex-grow" data-entry-id="{{ $entryId }}">{{ .String "title" }}</a>
                    <span class="mark-read-btn" data-entry-id="{{ $entryId }}" style="opacity: 0.3; cursor: pointer; font-size: 0.75rem; margin-left: 8px;" title="Mark as read">&times;</span>
                  </div>

                  <div class="flex justify-between items-center margin-top-3">
                    <span class="size-h6 color-dim">{{ $feedName }}</span>

                    {{/* Add timestamp as data attribute for JS processing */}}
                    {{ if gt $date 0 }}
                      <span class="size-h7 color-dim entry-date" data-timestamp="{{ $date }}">
                      </span>
                    {{ end }}
                  </div>

                  <div class="flex flex-wrap gap-5 margin-top-3">
                    {{ if $starred }}
                      <span class="text-xs" style="color: #f9e2af;">starred</span>
                    {{ end }}

                    {{ if ne $feedLabel "" }}
                      <span class="text-xs" style="color: {{ $feedColor }};">
                        {{ $feedLabel }}
                      </span>
                    {{ end }}
                  </div>
                </div>
              </div>
            </li>
          {{ end }}
        </ul>
      '';
    };
  in
    widget;
in {
  inherit mkCommaFeedWidget;
}
