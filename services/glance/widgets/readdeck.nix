{
  lib,
  PII,
  ...
}: let
  mkReadLaterWidget = {
    title ? "Read later",
    url ? lib.strings.concatImapStrings ["https://readlater." PII.domain "/api/bookmarks"],
    query ? "limit=10&is_archived=false&read_status=unread&read_status=reading",
    cache ? "10m",
    tokenPlaceholder ? "__READDECK_TOKEN__",
    labelMap ? {
      "tech" = "#89dceb";
      "devops" = "#a6e3a1";
      "linux" = "#a6e3a1";
      "programming" = "#74c7ec";
      "ai" = "#cba6f7";
      "business" = "#f9e2af";
      "entrepreneurial" = "#f9e2af";
      "gamemaster" = "#f5c2e7";
      "rpg" = "#f5c2e7";
      "news" = "#fab387";
    },
  }: let
    firstLabel = builtins.head (builtins.attrNames labelMap);
    firstColor = labelMap.${firstLabel};

    restLabels = builtins.tail (builtins.attrNames labelMap);
    restLabelLookup = lib.concatStringsSep "\n" (
      map
      (label: "{{ else if eq $label \"${label}\" }}{{ $labelColor = \"${labelMap.${label}}\" }}")
      restLabels
    );

    labelLookup = ''
      {{ if eq $label "${firstLabel}" }}{{ $labelColor = "${firstColor}" }}
        ${restLabelLookup}
      {{ end }}
    '';

    fullUrl = "${url}?${query}";

    widget = {
      type = "custom-api";
      inherit title cache;
      url = fullUrl;
      headers = {
        Authorization = "Bearer ${tokenPlaceholder}";
        Accept = "application/json";
      };
      template = ''
        <ul class="list list-gap-20">
          {{ range .JSON.Array "" }}
            {{ $progress := .Int "read_progress" }}

            <li class="padding-block-5 rounded-sm">
              <div style="position:relative" class="flex items-start gap-5">
                <div class="flex-grow page-column-full">
                  <a href="https://readlater.${PII.domain}/bookmarks/{{ .String "id" }}" class="color-highlight size-h4 block">{{ .String "title" }}</a>

                  <div class="flex justify-between items-center margin-top-3">
                    <span class="size-h6 color-dim">{{ .String "site_name" }}</span>

                    {{/* Display reading time if available */}}
                    {{ $readingTime := .Int "reading_time" }}
                    {{ if gt $readingTime 0 }}
                      <span class="size-h7 color-dim">{{ $readingTime }} min read</span>
                    {{ end }}
                  </div>

                  {{ if .Array "labels" }}
                    <div class="flex flex-wrap gap-5 margin-top-3">
                      {{ range .Array "labels" }}
                        {{ $label := .String "" }}
                        {{ $labelColor := "#6c7086" }}

                        ${labelLookup}

                        <span class="text-xs" style="color: {{ $labelColor }};">
                          {{ $label }}
                        </span>
                      {{ end }}
                    </div>
                  {{ end }}

                  {{/* Progress bar */}}
                  {{ if gt $progress 0 }}
                    <div style="margin-top: 8px; width: 100%; height: 4px; background-color: rgba(186, 194, 222, 0.1);">
                      <div style="height: 100%; width: {{ toFloat $progress }}%; background-color: rgba(186, 194, 222, 0.5);"></div>
                    </div>
                  {{ end }}
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
  inherit mkReadLaterWidget;
}
