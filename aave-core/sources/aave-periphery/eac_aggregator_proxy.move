module aave_pool::eac_aggregator_proxy {
    struct MockEacAggregatorProxy has key, drop, store, copy {}

    #[event]
    struct AnswerUpdated has store, drop {
        current: u256,
        round_id: u256,
        timestamp: u256,
    }

    #[event]
    struct NewRound has store, drop {
        round_id: u256,
        started_by: address
    }

    public fun decimals(): u8 {
        0
    }

    public fun latest_answer(): u256 {
        0
    }

    fun latest_timestamp(): u256 {
        0
    }

    fun latest_round(): u256 {
        0
    }

    fun get_answer(_round_id: u256): u256 {
        0
    }

    fun get_timestamp(_round_id: u256): u256 {
        0
    }

    public fun create_eac_aggregator_proxy(): MockEacAggregatorProxy {
        MockEacAggregatorProxy {}
    }
}
