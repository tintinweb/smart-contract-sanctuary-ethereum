//SPDX-License-Identifier: Unlicensed

/***
 *         ███████ ██    ██ ███████ ██████  ██    ██  ██████  ███    ██ ███████      ██████  ███████ ████████ ███████     
 *         ██      ██    ██ ██      ██   ██  ██  ██  ██    ██ ████   ██ ██          ██       ██         ██    ██          
 *         █████   ██    ██ █████   ██████    ████   ██    ██ ██ ██  ██ █████       ██   ███ █████      ██    ███████     
 *         ██       ██  ██  ██      ██   ██    ██    ██    ██ ██  ██ ██ ██          ██    ██ ██         ██         ██     
 *         ███████   ████   ███████ ██   ██    ██     ██████  ██   ████ ███████      ██████  ███████    ██    ███████     
 *                                                                                                                        
 *                                                                                                                        
 *                 ███████  ██████  ███    ███ ███████     ██████  ██    ██ ███████ ████████                              
 *                 ██      ██    ██ ████  ████ ██          ██   ██ ██    ██ ██         ██                                 
 *                 ███████ ██    ██ ██ ████ ██ █████       ██   ██ ██    ██ ███████    ██                                 
 *                      ██ ██    ██ ██  ██  ██ ██          ██   ██ ██    ██      ██    ██                                 
 *                 ███████  ██████  ██      ██ ███████     ██████   ██████  ███████    ██                                 
 *                                                                                                                        
 *            
 *    ETHER.CARDS - DUST TOKEN TRICKLING DISPENSER
 *
 * ┌────────┬───────┬─────────┬─────────────────────────┬───────────┬─────────────┬────────────────┬───────────┬────────────┬──────────────┬─────────────────┐
 * │ Period │ 1 Day │ Blocks  │ BLOCK_START │ BLOCK_END │ /Block OG │/Block Alpha │ /Block Founder │ Total OG  │Total Alpha │Total Founder │ All Total       │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 0      │ 40000 │ 1200000 │    24400431 │  25600431 │ 0.0048660 │  0.00095238 │ 0.000148810000 │  5,839.28 │  1,142.856 │    178.57200 │  3161254.230000 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 1      │ 40000 │ 1200000 │    25600432 │  26800432 │ 0.0064880 │  0.00126984 │ 0.000198413333 │  7,785.71 │  1,523.808 │    238.09596 │  4215005.639999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 2      │ 40000 │ 1200000 │    26800433 │  28000433 │ 0.0081101 │  0.00158730 │ 0.000248016666 │  9,732.14 │  1,904.760 │    297.61992 │  5268757.049999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 3      │ 40000 │ 1200000 │    28000434 │  29200434 │ 0.0097321 │  0.00190476 │ 0.000297620000 │ 11,678.57 │  2,285.712 │    357.14400 │  6322508.460000 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 4      │ 40000 │ 1200000 │    29200435 │  30400435 │ 0.0113541 │  0.00222222 │ 0.000347223333 │ 13,625.00 │  2,666.664 │    416.66796 │  7376259.869999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 5      │ 40000 │ 1200000 │    30400436 │  31600436 │ 0.0129761 │  0.00253968 │ 0.000396826666 │ 15,571.43 │  3,047.616 │    476.19192 │  8430011.279999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 6      │ 40000 │ 1200000 │    31600437 │  32800437 │ 0.0162202 │  0.00317460 │ 0.000496033333 │ 19,464.28 │  3,809.520 │    595.23996 │ 10537514.099999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 7      │ 40000 │ 1200000 │    32800438 │  34000438 │ 0.0210863 │  0.00412698 │ 0.000644843333 │ 25,303.57 │  4,952.376 │    773.81196 │ 13698768.329999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 8      │ 40000 │ 1200000 │    34000439 │  35200439 │ 0.0259523 │  0.00507936 │ 0.000793653333 │ 31,142.86 │  6,095.232 │    952.38396 │ 16860022.559999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 9      │ 40000 │ 1200000 │    35200440 │  36400440 │ 0.0324404 │  0.00634920 │ 0.000992066666 │ 38,928.57 │  7,619.040 │ 1,190.479999 │ 21075028.199999 │
 * ├────────┼───────┼─────────┼─────────────┼───────────┼───────────┼─────────────┼────────────────┼───────────┼────────────┼──────────────┼─────────────────┤
 * │ 10     │ 40000 │ 1200000 │    36400441 │  37600441 │ 0.0454166 │  0.00888888 │ 0.001388893333 │ 54,500.01 │ 10,666.656 │ 1,666.671999 │ 29505039.479999 │
 * └────────┴───────┴─────────┴─────────────┴───────────┴───────────┴─────────────┴────────────────┴───────────┴────────────┴──────────────┴─────────────────┘
 *
 * ┌────────────────┬──────────────┬───────────────────┬──────────────────────┐
 * │ Total OG       │ Total Alpha  │ Total Founder     │ All Cards Total      │
 * ├────────────────┼──────────────┼───────────────────┼──────────────────────┤
 * │  21,021,433.19 │ 41,142,816.0 │ 64,285,919.999999 │ 126,450,169.19999995 │
 * └────────────────┴──────────────┴───────────────────┴──────────────────────┘
 * 
 * ┌─────────┬────────────┬────────────────┐
 * │ Type    │ Card Limit │ Total Alpha    │
 * ├─────────┼────────────┼────────────────┤
 * │ OG      │ 19,464.29  │ 233,571        │
 * ├─────────┼────────────┼────────────────┤
 * │ ALPHA   │ 3,809.52   │ 45,714         │
 * ├─────────┼────────────┼────────────────┤
 * │ FOUNDER │ 595.24     │ 7,143          │
 * └─────────┴────────────┴────────────────┘
 *
 */

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IECRegistryV2.sol";

contract DustDispenserV2 is Ownable {
    
    using SafeMath for uint256;
    using SafeMath for uint16;
    using EnumerableSet for EnumerableSet.AddressSet;

    // onlyOwner can change contractControllers and transfer it's ownership
    EnumerableSet.AddressSet contractController;

    IECRegistry public              ECRegistry;
    IERC721     public              erc721;     // Ether Cards
    IERC20      public              erc20;      // Dust

    uint8       public constant     CARD_TYPE_OG = 1;
    uint8       public constant     CARD_TYPE_ALPHA = 2;
    uint8       public constant     CARD_TYPE_FOUNDER = 3;

    uint256     public immutable    START_BLOCK;

    mapping(uint16 => uint256) public withdrawnAtBlock;   // last time a card id withdrew at
    mapping(uint16 => uint16)  public withdrawnAtRateId;  // last rate ID a card id withdrew at
    mapping(uint16 => uint256) public cardLimitsByType;
    
    struct cardRateStruct {
        uint256 RATE;
        uint256 BLOCK_LENGTH;
        uint256 BLOCK_START;
        uint256 BLOCK_END;
    }
    mapping(uint16 => mapping(uint8 => cardRateStruct)) public cardRatesByType;
    uint16 public cardRateCount = 0;

    struct traitRateStruct {
        uint16  traitId;
        uint256 rate_millis;   // millis
    }
    mapping(uint16 => traitRateStruct) public traitRates;
    uint256 public traitRatesCount;

    bool        public  locked = false;

    event contractControllerEvent(address _address, bool mode);
    event traitRatesChangedEvent(uint16 traitId, uint256 rate);

    constructor(
        address _registry,
        address _erc721,
        address _erc20,
        uint256 _start_block
    ) {
        ECRegistry = IECRegistry(_registry);
        erc721 = IERC721(_erc721);
        erc20 = IERC20(_erc20);
        START_BLOCK = _start_block;
    }

    function updateAddresses(
        address _registry,
        address _erc721,
        address _erc20
    ) external onlyAllowed {
        if(_registry != address(0)) {
            ECRegistry = IECRegistry(_registry);
        }

        if(_erc721 != address(0)) {
            erc721 = IERC721(_erc721);
        }

        if(_erc20 != address(0)) {
            erc20 = IERC20(_erc20);
        }
    }

    function addCardRates(
        uint256[] calldata block_length,
        uint256[] calldata rate_og,
        uint256[] calldata rate_alpha,
        uint256[] calldata rate_founder
    ) public onlyAllowed {

        uint256 calcBlockStart;
        uint256 calcBlockEnd;

        for(uint8 i = 0; i < block_length.length; i++) {

            cardRatesByType[cardRateCount][CARD_TYPE_OG].BLOCK_LENGTH       = block_length[i];
            cardRatesByType[cardRateCount][CARD_TYPE_ALPHA].BLOCK_LENGTH    = block_length[i];
            cardRatesByType[cardRateCount][CARD_TYPE_FOUNDER].BLOCK_LENGTH  = block_length[i];
            cardRatesByType[cardRateCount][CARD_TYPE_OG].RATE       = rate_og[i];
            cardRatesByType[cardRateCount][CARD_TYPE_ALPHA].RATE    = rate_alpha[i];
            cardRatesByType[cardRateCount][CARD_TYPE_FOUNDER].RATE  = rate_founder[i];

            // calculate block start / end 
            if(cardRateCount == 0) {
                calcBlockStart = START_BLOCK;
                calcBlockEnd = START_BLOCK.add(block_length[i]);
            } else {
                
                // previous end + 1
                calcBlockStart = cardRatesByType[cardRateCount-1][CARD_TYPE_OG].BLOCK_END.add(1);
                calcBlockEnd = calcBlockStart.add(block_length[i]);
            }

            cardRatesByType[cardRateCount][CARD_TYPE_OG].BLOCK_START        = calcBlockStart;
            cardRatesByType[cardRateCount][CARD_TYPE_OG].BLOCK_END          = calcBlockEnd;
            cardRatesByType[cardRateCount][CARD_TYPE_ALPHA].BLOCK_START     = calcBlockStart;
            cardRatesByType[cardRateCount][CARD_TYPE_ALPHA].BLOCK_END       = calcBlockEnd;
            cardRatesByType[cardRateCount][CARD_TYPE_FOUNDER].BLOCK_START   = calcBlockStart;
            cardRatesByType[cardRateCount][CARD_TYPE_FOUNDER].BLOCK_END     = calcBlockEnd;

            cardRateCount++;
        }
    }

    function updateCardRates(
        uint16 rate_id,
        uint256 block_length,
        uint256 rate_og,
        uint256 rate_alpha,
        uint256 rate_founder
    ) public onlyAllowed {

        cardRatesByType[rate_id][CARD_TYPE_OG].BLOCK_LENGTH       = block_length;
        cardRatesByType[rate_id][CARD_TYPE_ALPHA].BLOCK_LENGTH    = block_length;
        cardRatesByType[rate_id][CARD_TYPE_FOUNDER].BLOCK_LENGTH  = block_length;
        cardRatesByType[rate_id][CARD_TYPE_OG].RATE       = rate_og;
        cardRatesByType[rate_id][CARD_TYPE_ALPHA].RATE    = rate_alpha;
        cardRatesByType[rate_id][CARD_TYPE_FOUNDER].RATE  = rate_founder;

        // update calculated block start / end from this rate id onward
        uint256 calcBlockStart;
        uint256 calcBlockEnd;
        for(uint16 i = rate_id; i < cardRateCount; i++) {

            if(i == 0) {
                calcBlockStart = START_BLOCK;
                calcBlockEnd = START_BLOCK.add(block_length);
            } else {
                // previous record end + 1
                calcBlockStart = cardRatesByType[i-1][CARD_TYPE_OG].BLOCK_END.add(1);

                // this record old block length
                calcBlockEnd = calcBlockStart.add(
                    cardRatesByType[i][CARD_TYPE_OG].BLOCK_LENGTH
                );
            }

            cardRatesByType[i][CARD_TYPE_OG].BLOCK_START        = calcBlockStart;
            cardRatesByType[i][CARD_TYPE_OG].BLOCK_END          = calcBlockEnd;
            cardRatesByType[i][CARD_TYPE_ALPHA].BLOCK_START     = calcBlockStart;
            cardRatesByType[i][CARD_TYPE_ALPHA].BLOCK_END       = calcBlockEnd;
            cardRatesByType[i][CARD_TYPE_FOUNDER].BLOCK_START   = calcBlockStart;
            cardRatesByType[i][CARD_TYPE_FOUNDER].BLOCK_END     = calcBlockEnd;
        }

    }

    function setTraitRates (
        uint16[] memory _traitIds,
        uint256[] memory _rates
    ) public onlyAllowed {
        uint8 i = 0;
        while(i < _traitIds.length) {
            traitRateStruct storage t = traitRates[i];
            t.traitId = _traitIds[i];
            t.rate_millis = _rates[i];
            emit traitRatesChangedEvent(_traitIds[i], _rates[i]);
            i++;
        }
        traitRatesCount = i;
    }

    function setCardLimits(
        uint256 limit_og,
        uint256 limit_alpha,
        uint256 limit_founder
    ) public onlyAllowed {
        cardLimitsByType[CARD_TYPE_OG] = limit_og;
        cardLimitsByType[CARD_TYPE_ALPHA] = limit_alpha;
        cardLimitsByType[CARD_TYPE_FOUNDER] = limit_founder;
    }

    function toggleLocked () public onlyAllowed {
        locked = !locked;
    }

    function getCurrentRateId() public view returns (uint16 rateId) {

        uint256 currentBlockNumber = getBlockNumber();
        uint16 lastcardRateEntryId = uint16(cardRateCount.sub(1));
        uint256 blockEnd   = cardRatesByType[lastcardRateEntryId][CARD_TYPE_OG].BLOCK_END;
        uint256 blockStart = cardRatesByType[0][CARD_TYPE_OG].BLOCK_START;

        // edge case 1 - current block is higher than any rate available BLOCK_END
        if(currentBlockNumber > blockEnd) {
            return lastcardRateEntryId;
        }

        // edge case 2
        if(currentBlockNumber < blockStart) {
            revert("Current block is before START_BLOCK");
        }

        for(uint16 i = lastcardRateEntryId; i >= 0; i--) {
            blockEnd   = cardRatesByType[i][CARD_TYPE_OG].BLOCK_END;
            blockStart = cardRatesByType[i][CARD_TYPE_OG].BLOCK_START;
            if(currentBlockNumber >= blockStart && currentBlockNumber <= blockEnd ) {
                return i;
            }
        }

        // should never happen.
        revert("Unhandled exception!");
    }


    /**
     * @notice Return the claimable balance for token id
     */
    function getAvailableBalance(uint16 _tokenId) public view returns (uint256 balance) {
        uint8 cardType = getCardTypeFromId(_tokenId);
        uint256 cardLimit = cardLimitsByType[cardType];

        uint256 token_start_block = withdrawnAtBlock[_tokenId];
        // everyone starts at START_BLOCK
        if(token_start_block < START_BLOCK) {
            token_start_block = START_BLOCK;
        }

        uint256 blocksPassedSinceLastWithdrawal = getBlockNumber().sub(token_start_block);

        // start at the last rate ID withdrew at
        uint16 rate_start_id = withdrawnAtRateId[_tokenId];

        for(uint16 i = rate_start_id; i < cardRateCount; i++) {

            // card rates
            cardRateStruct storage rate = cardRatesByType[i][cardType];
            uint256 blocksLeftAtThisRate = 0;

            // edge case 1 - if token_start_block is higher than last rate end block
            //               this means no balance is left
            if(token_start_block > rate.BLOCK_END) {
                blocksLeftAtThisRate = 0;
            } else {
                // find out how many blocks at this rate we can claim
                blocksLeftAtThisRate = rate.BLOCK_END.sub(token_start_block);
            }

            uint256 blockCountToRedeemAtThisRate = blocksPassedSinceLastWithdrawal;
            if(blocksPassedSinceLastWithdrawal > blocksLeftAtThisRate ) {
                blockCountToRedeemAtThisRate = blocksLeftAtThisRate;
            }

            blocksPassedSinceLastWithdrawal = blocksPassedSinceLastWithdrawal.sub(blockCountToRedeemAtThisRate);
            balance = balance.add( blockCountToRedeemAtThisRate.mul(rate.RATE) );

            // if balance is at LIMIT
            if(balance > cardLimit ) {
                return cardLimit;
            }

            // if no blocks are left exit
            if(blocksPassedSinceLastWithdrawal == 0) {
                i = cardRateCount;
            }
        }

        // Apply TRAIT Modifiers
        uint256 per_mille = balance.div(1000);
        for(uint8 i = 0; i < traitRatesCount; i++) {
            traitRateStruct storage traitRate = traitRates[i];
            if(ECRegistry.hasTrait(traitRate.traitId, _tokenId)) {
                balance = balance.add(
                    traitRate.rate_millis.mul(per_mille)
                );
            }

            // if balance is at LIMIT
            if(balance > cardLimit ) {
                return cardLimit;
            }
        }

        return balance;
    }

    /**
     * @notice Return the claimable balance for token ids array
     */
    function getAvailableBalance(uint16[] calldata _tokenIds) public view returns (uint256 balance) {
        for(uint16 i = 0; i < _tokenIds.length; i++) {
            balance = balance.add( getAvailableBalance(_tokenIds[i]) );
        }
    }

    /**
     * @notice Redeem available balance for specified token ids array
     */
    function redeem(uint16[] calldata _tokenIds) public {
        uint256 totalAmount;
        uint256 currentBlockNumber = getBlockNumber();
        uint16 currentRateId = getCurrentRateId();

        for(uint8 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];

            // check token ownership
            require(erc721.ownerOf(_tokenId) == msg.sender, "ERC721: not owner of token");
            totalAmount = totalAmount.add(getAvailableBalance(_tokenId));
            withdrawnAtBlock[_tokenId] = currentBlockNumber;
            withdrawnAtRateId[_tokenId] = currentRateId;
        }
        
        erc20.transfer(msg.sender, totalAmount);
    }

    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
    }

    function getCardTypeFromId(uint16 _tokenId) public pure returns (uint8 _cardType) {
        if(_tokenId < 10) {
            revert("CartType not allowed");
        }
        if(_tokenId < 100) {
            return CARD_TYPE_OG;
        }
        if (_tokenId < 1000) {
            return CARD_TYPE_ALPHA;
        } 
        if (_tokenId < 10000) {
            return CARD_TYPE_FOUNDER;
        }
        revert("CartType not found");
    }

    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit contractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }

    function getContractControllers()
        external
        view
        returns (address[] memory _allowed)
    {
        _allowed = new address[](contractController.length());
        for (uint256 i = 0; i < contractController.length(); i++) {
            _allowed[i] = contractController.at(i);
        }
        return _allowed;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "Not Authorised"
        );
        _;
    }

    // blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount) external onlyAllowed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;

interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
    function setTraitOnTokens(uint16 traitID, uint16[] memory tokenID, bool[] memory) external;
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}