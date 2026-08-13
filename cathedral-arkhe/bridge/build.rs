fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(false)
        .file_descriptor_set_path(std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("cathedral_descriptor.bin")).compile(
            &["../proto/cathedral/v1/bridge.proto"],
            &["../proto/"],
        )?;
    println!("cargo:rerun-if-changed=../proto/cathedral/v1/bridge.proto");
    Ok(())
}
