// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICLJ{
    function burn(uint _token_id) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract CLJUpgrader {

    event BurnedForUpgrade(uint256 indexed upgradedId, uint256 indexed burnedId);

    error TokenIdNotOwned();
    error CapReached(uint rank);
    error RequireExactBurnAmount();
    error Reentered();

    ICLJ public immutable clj;

    mapping(uint256 => uint256) public tokenUpgradeCount;
    mapping(uint256 => uint256) public rankCount;

    uint256 immutable SILVER_CAP;
    uint256 immutable GOLD_CAP;
    uint256 immutable PLATINUM_CAP;
    uint256 immutable DIAMOND_CAP;

    uint8 immutable BRONZE_THRESH = 1;
    uint8 immutable SILVER_THRESH = 2;
    uint8 immutable GOLD_THRESH = 4;
    uint8 immutable PLATINUM_THRESH = 6;
    uint8 immutable DIAMOND_THRESH = 10;

    uint256 internal _ENTERED = 1;

    modifier noReenter() {
        if (_ENTERED != 1) revert Reentered();
        _ENTERED = 2;
        _;
        _ENTERED = 1;
    }

    constructor(uint256[] memory caps){
        clj = ICLJ(0x867ba3C89fB7C8F4d72068859c26d147F5330043);

        SILVER_CAP = caps[0];
        GOLD_CAP = caps[1];
        PLATINUM_CAP = caps[2];
        DIAMOND_CAP = caps[3];

        rankCount[DIAMOND_THRESH] = 35;
    }

    function burnToUpgrade(uint256 tokenIdToUpgrade, uint256[] calldata tokenIdsToBurn)
    external
    noReenter{

        if (msg.sender != clj.ownerOf(tokenIdToUpgrade)){
                revert TokenIdNotOwned();
        }

        uint256 sumTokenValues;

        for (uint i=0; i<tokenIdsToBurn.length; i++){
            uint256 tokenIdToBurn = tokenIdsToBurn[i];
            if (msg.sender != clj.ownerOf(tokenIdToBurn)){
                revert TokenIdNotOwned();
            }
            uint256 tokenCount = tokenUpgradeCount[tokenIdToBurn];
            sumTokenValues += tokenCount + 1;

            //do this before upgrade, in case a capped rank frees a slot
            decrementCounter(tokenCount);

            delete tokenUpgradeCount[tokenIdToBurn];
            //breaks checks-effects-interactions-pattern, but should be fine
            clj.burn(tokenIdToBurn);
            emit BurnedForUpgrade(tokenIdToUpgrade, tokenIdToBurn);
        }
        upgradeIfAllowed(tokenIdToUpgrade, sumTokenValues);
    }

    function decrementCounter(uint256 tokenCount) internal{
        if (tokenCount > 0) {
            --rankCount[tokenCount];
        }
    }

    function upgradeIfAllowed(uint256 tokenIdToUpgrade, uint256 sumTokenValues) internal{
        uint256 previousCount = tokenUpgradeCount[tokenIdToUpgrade];
        uint256 nextUpgradeCount = previousCount + sumTokenValues;
        if(nextUpgradeCount == BRONZE_THRESH){
            //NOOP
        } else if (nextUpgradeCount == SILVER_THRESH){
            if (rankCount[SILVER_THRESH]+1 > SILVER_CAP) {
                revert CapReached(SILVER_THRESH);
            }
        } else if (nextUpgradeCount == GOLD_THRESH){
            if (rankCount[GOLD_THRESH]+1 > GOLD_CAP) {
                revert CapReached(GOLD_THRESH);
            }
        } else if (nextUpgradeCount == PLATINUM_THRESH){
            if (rankCount[PLATINUM_THRESH]+1 > PLATINUM_CAP) {
                revert CapReached(PLATINUM_THRESH);
            }
        } else if (nextUpgradeCount == DIAMOND_THRESH){
            if (rankCount[DIAMOND_THRESH]+1 > DIAMOND_CAP) {
                revert CapReached(DIAMOND_THRESH);
            }
        } else {
            revert RequireExactBurnAmount();
        }

        tokenUpgradeCount[tokenIdToUpgrade] = nextUpgradeCount;
        if (previousCount > 0) {
            --rankCount[previousCount];
        }
        ++rankCount[nextUpgradeCount];
    }
}