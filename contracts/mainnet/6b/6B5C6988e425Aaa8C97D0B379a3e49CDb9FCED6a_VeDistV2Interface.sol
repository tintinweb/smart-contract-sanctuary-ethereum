// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract VeDistV2Interface {
    event CheckpointToken(uint256 time, uint256 tokens);
    event Claimed(
        uint256 tokenId,
        uint256 amount,
        uint256 claim_epoch,
        uint256 max_epoch
    );

    function checkpoint_token() external {}

    function checkpoint_total_supply() external {}

    function claim(uint256 _tokenId) external returns (uint256) {}

    function claim_many(uint256[] memory _tokenIds) external returns (bool) {}

    function claimable(uint256 _tokenId) external view returns (uint256) {}

    function depositor() external view returns (address) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(address _voting_escrow) external {}

    function last_token_time() external view returns (uint256) {}

    function setDepositor(address _depositor) external {}

    function start_time() external view returns (uint256) {}

    function time_cursor() external view returns (uint256) {}

    function time_cursor_of(uint256) external view returns (uint256) {}

    function timestamp() external view returns (uint256) {}

    function token() external view returns (address) {}

    function token_last_balance() external view returns (uint256) {}

    function tokens_per_week(uint256) external view returns (uint256) {}

    function user_epoch_of(uint256) external view returns (uint256) {}

    function ve_for_at(uint256 _tokenId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {}

    function ve_supply(uint256) external view returns (uint256) {}

    function voting_escrow() external view returns (address) {}
}