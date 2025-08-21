#[test_only]
module aave_config::revision_tests {
    use aptos_std::string_utils;
    use aave_config::revision;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    const MAJOR_REVISION: u256 = 1;
    const MINOR_REVISION: u256 = 1;
    const PATCH_REVISION: u256 = 0;

    #[test]
    fun test_revision_getter() {
        let revision = revision::get_revision();
        let expected_revision =
            string_utils::format3(
                &b"{}.{}.{}",
                revision::get_major_revision(),
                revision::get_minor_revision(),
                revision::get_patch_revision()
            );
        assert!(expected_revision == revision);
    }
}
