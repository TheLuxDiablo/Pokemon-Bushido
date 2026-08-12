module BushidoEventExporter
  EXPORT_FOLDER = "EventExports"

  def self.load_map(map_id)
    filename = sprintf("Data/Map%03d.rxdata", map_id)

    unless FileTest.exist?(filename)
      raise "Map file not found: #{filename}"
    end

    return load_data(filename)
  end

  def self.ensure_export_folder
    unless FileTest.directory?(EXPORT_FOLDER)
      Dir.mkdir(EXPORT_FOLDER)
    end
  end

  def self.sanitize_filename(name)
    name = name.to_s.strip

    if name.empty?
      name = "Unnamed"
    end

    name = name.gsub(/[\\\/:\*\?"<>\|]/, "_")
    name = name.gsub(/\s+/, "_")

    return name
  end

  def self.get_map_name(map_id)
    begin
      map_infos = load_data("Data/MapInfos.rxdata")

      if map_infos && map_infos[map_id]
        return map_infos[map_id].name
      end
    rescue
    end

    return sprintf("Map%03d", map_id)
  end

  def self.build_event_list_text(map_id)
    map = load_map(map_id)
    map_name = get_map_name(map_id)

    output = []

    output << "========================================"
    output << "BUSHIDO EVENT EXPORTER"
    output << "========================================"
    output << ""
    output << "Map: #{map_name}"
    output << "Map ID: #{map_id}"
    output << ""
    output << "----------------------------------------"
    output << "EVENTS"
    output << "----------------------------------------"

    if !map.events || map.events.empty?
      output << "No events found."
    else
      map.events.keys.sort.each do |event_id|
        event = map.events[event_id]

        output << sprintf(
          "[%03d] %s (X: %d, Y: %d)",
          event.id,
          event.name,
          event.x,
          event.y
        )
      end

      output << ""
      output << "----------------------------------------"
      output << "#{map.events.length} event(s) found."
    end

    return output.join("\n")
  end

  def self.export_event_list(map_id)
    ensure_export_folder

    map_name = get_map_name(map_id)
    text = build_event_list_text(map_id)

    filename = sprintf(
      "%s/%03d_%s_EVENTS.txt",
      EXPORT_FOLDER,
      map_id,
      sanitize_filename(map_name)
    )

    File.open(filename, "wb") do |file|
      file.write(text)
    end

    print(
      "Event export complete!\n\n" +
      "Saved to:\n#{filename}\n\n" +
      "Open the EventExports folder in your Bushido project."
    )

    return filename
  end
end