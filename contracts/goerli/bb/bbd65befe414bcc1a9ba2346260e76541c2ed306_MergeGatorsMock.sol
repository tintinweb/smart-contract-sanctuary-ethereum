pragma solidity ^0.8.4;

import "../../src/MergeGators.sol";

contract MergeGatorsMock is MergeGators {
    address constant owner_ = 0xC5Fcd6be4a3b187Cb9B3Bbd9aAD047767DAEF344;
    uint256 constant taxPay_ = 0.0001 ether;
    //11
    address constant collection = 0x1CBf6D670bC8BaE6aa3615479e8371a56A4eBe8F;
    address payable constant taxTreasuryAddr = payable(0xf288C4AbFB34976e80aa61cd65862F465DAfB6EA);

    uint256 constant prizeBPS = 3;
    uint256 constant prizePortionBPS = 30;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2,
        bytes32 gasLane
        )
        MergeGators(
                owner_,
                collection,
                taxTreasuryAddr,
                taxPay_,
                subscriptionId,
                vrfCoordinatorV2,
                gasLane,
                prizeBPS,
                prizePortionBPS)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// _______________________________________________________________________
//     _   _                              __                              
//     /  /|                            /    )                            
// ---/| /-|----__---)__----__----__---/---------__--_/_----__---)__---__-
//   / |/  |  /___) /   ) /   ) /___) /  --,   /   ) /    /   ) /   ) (_ `
// _/__/___|_(___ _/_____(___/_(___ _(____/___(___(_(_ __(___/_/_____(__)_
//                          /                                             
//                      (_ /                                              

import {Alligators} from './Alligators.sol';
import './extension/Ownable.sol';
import './chainlink/VRFConsumerBaseV2.sol';
import './chainlink/VRFCoordinatorV2Interface.sol';
import './interface/IMergeGators.sol';

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract MergeGators is IMergeGators, Ownable, VRFConsumerBaseV2 {

    /*//////////////////////////////////////////////////////////////
                               MERGE GATORS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => RequestStatus) private vrf_requests;


    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit = 100000;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable gasLane;

    VRFCoordinatorV2Interface private immutable _vrfCoordinator;

    uint256 internal constant MAX_CHANCE_VALUE = 1000;
    uint256 internal MIN_CHANCE_VALUE = 777;

    uint256 private _taxAmount;
    uint256 private _rewardPortion;
    uint256 private _prizeBps;
    uint256 private _prizePortionBps;

    address private _ownerAddr;

    address payable public taxTreasury;

    Alligators public alligators;

    constructor(
        address ownerAddr,
        address _BEP721,
        address payable _taxTreasuryAddress,
        uint256 _taxPay,
        uint64 subscriptionId_,
        address vrfCoordinatorV2_,
        bytes32 gasLane_,
        uint256 prizeBps_,
        uint256 prizePortionBps_
    ) VRFConsumerBaseV2(vrfCoordinatorV2_) {

            _ownerAddr = ownerAddr;
            _setupOwner(_ownerAddr);

            alligators = Alligators(_BEP721);
            taxTreasury = _taxTreasuryAddress;

            _taxAmount = _taxPay;

            _prizeBps = prizeBps_;
            _prizePortionBps = prizePortionBps_;

            subscriptionId = subscriptionId_;
            _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
            gasLane = gasLane_;
        }
    
    
    function merge(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable {

        if (alligators.tokenType(_1st) == 3 || alligators.tokenType(_2nd) == 3 || alligators.tokenType(_3rd) == 3) revert Mergefailed();

        require(msg.value >= _taxAmount, "Tax Amount is not enough");

        payable(taxTreasury).transfer(_taxAmount - _calculatePortionToRewardPool());
        payable(address(this)).transfer(_calculatePortionToRewardPool());

        uint8[2] memory _1stType = _compareTrait(_1st, _2nd, _3rd, 0);
        uint8[2] memory _2ndType = _compareTrait(_1st, _2nd, _3rd, 1);
        uint8[2] memory _3rdType = _compareTrait(_1st, _2nd, _3rd, 2);
        uint8[2] memory _4thType = _compareTrait(_1st, _2nd, _3rd, 3);
        uint8[2] memory _5thType = _compareTrait(_1st, _2nd, _3rd, 4);
        uint8[2] memory _6thType = _compareTrait(_1st, _2nd, _3rd, 5);
        uint8[2] memory _7thType = _compareTrait(_1st, _2nd, _3rd, 6);

        lvlUp levelUp = lvlUp.FALSE;

        // Generate Merged NFT
        if (alligators.anatomy(_1st)[0] == alligators.anatomy(_2nd)[0] && alligators.anatomy(_1st)[0] == alligators.anatomy(_3rd)[0]) {
            if (alligators.traitLevels(_1st)[0] == alligators.traitLevels(_2nd)[0] && alligators.traitLevels(_1st)[0] == alligators.traitLevels(_3rd)[0]) {
                if (alligators.traitLevels(_1st)[0] < 5) {
                    _1stType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (alligators.anatomy(_1st)[1] == alligators.anatomy(_2nd)[1] && alligators.anatomy(_1st)[1] == alligators.anatomy(_3rd)[1]) {
            if (alligators.traitLevels(_1st)[1] == alligators.traitLevels(_2nd)[1] && alligators.traitLevels(_1st)[1] == alligators.traitLevels(_3rd)[1]) {
                if (alligators.traitLevels(_1st)[1] < 5) {
                    _2ndType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (alligators.anatomy(_1st)[2] == alligators.anatomy(_2nd)[2] && alligators.anatomy(_1st)[2] == alligators.anatomy(_3rd)[2]) {
            if (alligators.traitLevels(_1st)[2] == alligators.traitLevels(_2nd)[2] && alligators.traitLevels(_1st)[2] == alligators.traitLevels(_3rd)[2]) {
                if (alligators.traitLevels(_1st)[2] < 5) {
                    _3rdType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (alligators.anatomy(_1st)[3] == alligators.anatomy(_2nd)[3] && alligators.anatomy(_1st)[3] == alligators.anatomy(_3rd)[3]) {
            if (alligators.traitLevels(_1st)[3] == alligators.traitLevels(_2nd)[3] && alligators.traitLevels(_1st)[3] == alligators.traitLevels(_3rd)[3]) {
                if (alligators.traitLevels(_1st)[3] < 5) {
                    _4thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (alligators.anatomy(_1st)[4] == alligators.anatomy(_2nd)[4] && alligators.anatomy(_1st)[4] == alligators.anatomy(_3rd)[4]) {
            if (alligators.traitLevels(_1st)[4] == alligators.traitLevels(_2nd)[4] && alligators.traitLevels(_1st)[4] == alligators.traitLevels(_3rd)[4]) {
                if (alligators.traitLevels(_1st)[4] < 5) {
                    _5thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (alligators.anatomy(_1st)[5] == alligators.anatomy(_2nd)[5] && alligators.anatomy(_1st)[5] == alligators.anatomy(_3rd)[5]) {
            if (alligators.traitLevels(_1st)[5] == alligators.traitLevels(_2nd)[5] && alligators.traitLevels(_1st)[5] == alligators.traitLevels(_3rd)[5]) {
                if (alligators.traitLevels(_1st)[5] < 5) {
                    _6thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (alligators.anatomy(_1st)[6] == alligators.anatomy(_2nd)[6] && alligators.anatomy(_1st)[6] == alligators.anatomy(_3rd)[6]) {
            if(alligators.traitLevels(_1st)[6] == alligators.traitLevels(_2nd)[6] && alligators.traitLevels(_1st)[6] == alligators.traitLevels(_3rd)[6]) {
                if (alligators.traitLevels(_1st)[6] < 5) {
                    _7thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }

        if (levelUp != lvlUp.TRUE) revert Mergefailed();

        alligators.createSkeleton(
            _1stType[0],
            _2ndType[0],
            _3rdType[0],
            _4thType[0],
            _5thType[0],
            _6thType[0],
            _7thType[0]
            );

            alligators.createLevels(
            _1stType[1],
            _2ndType[1],
            _3rdType[1],
            _4thType[1],
            _5thType[1],
            _6thType[1],
            _7thType[1]
        );
    
        alligators.merge(_1st, _2nd, _3rd, msg.sender);

        _mergePrize(msg.sender);

        emit mergeFulfilled(alligators.currentMergeId());
    }


    function mergeWithJoker(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable {
        require(msg.value >= _taxAmount, "Tax Amount is not enough");
        if (alligators.tokenType(_1st) != 3) revert Mergefailed();
        if (alligators.tokenType(_2nd) == 3 || alligators.tokenType(_3rd) == 3) revert Mergefailed();

        payable(taxTreasury).transfer(_taxAmount - _calculatePortionToRewardPool());
        payable(address(this)).transfer(_calculatePortionToRewardPool());

        uint8[2] memory _1stType = _compareTraitJoker(_2nd, _3rd, 0);
        uint8[2] memory _2ndType = _compareTraitJoker(_2nd, _3rd, 1);
        uint8[2] memory _3rdType = _compareTraitJoker(_2nd, _3rd, 2);
        uint8[2] memory _4thType = _compareTraitJoker(_2nd, _3rd, 3);
        uint8[2] memory _5thType = _compareTraitJoker(_2nd, _3rd, 4);
        uint8[2] memory _6thType = _compareTraitJoker(_2nd, _3rd, 5);
        uint8[2] memory _7thType = _compareTraitJoker(_2nd, _3rd, 6);

        lvlUp levelUp = lvlUp.FALSE;

        uint8 JokerLvl = alligators.JokerLevel(_1st);

        if (JokerLvl == alligators.traitLevels(_2nd)[0] && JokerLvl == alligators.traitLevels(_3rd)[0]) {
            if (alligators.traitLevels(_2nd)[0] < 5) {
            _1stType[1]++;
            levelUp = lvlUp.TRUE;
            }
        }
        
        if (JokerLvl == alligators.traitLevels(_2nd)[1] && JokerLvl == alligators.traitLevels(_3rd)[1]) {
            if (alligators.traitLevels(_2nd)[1] < 5) {
                _2ndType[1]++;
                levelUp = lvlUp.TRUE;
            }
        }
        
        if (JokerLvl == alligators.traitLevels(_2nd)[2] && JokerLvl == alligators.traitLevels(_3rd)[2]) {
            if (alligators.traitLevels(_2nd)[2] < 5) {
                _3rdType[1]++;
                levelUp = lvlUp.TRUE;
            }
        }
        
        if (JokerLvl == alligators.traitLevels(_2nd)[3] && JokerLvl == alligators.traitLevels(_3rd)[3]) {
            if (alligators.traitLevels(_2nd)[3] < 5) {
                _4thType[1]++;
                levelUp = lvlUp.TRUE;
            }
        }
        
        if (JokerLvl == alligators.traitLevels(_2nd)[4] && JokerLvl == alligators.traitLevels(_3rd)[4]) {
            if (alligators.traitLevels(_2nd)[4] < 5) {
                _5thType[1]++;
                levelUp = lvlUp.TRUE;
            }
        }
        
        if (JokerLvl == alligators.traitLevels(_2nd)[5] && JokerLvl == alligators.traitLevels(_3rd)[5]) {
            if (alligators.traitLevels(_2nd)[5] < 5) {
                _6thType[1]++;
                levelUp = lvlUp.TRUE;
            }
        }
        
        if (JokerLvl == alligators.traitLevels(_2nd)[6] && JokerLvl == alligators.traitLevels(_3rd)[6]) {
            if (alligators.traitLevels(_2nd)[6] < 5) {
                _7thType[1]++;
                levelUp = lvlUp.TRUE;
            }
        }

        if (levelUp != lvlUp.TRUE) revert Mergefailed();
        
        alligators.createSkeleton(
            _1stType[0],
            _2ndType[0],
            _3rdType[0],
            _4thType[0],
            _5thType[0],
            _6thType[0],
            _7thType[0]
            );

            alligators.createLevels(
            _1stType[1],
            _2ndType[1],
            _3rdType[1],
            _4thType[1],
            _5thType[1],
            _6thType[1],
            _7thType[1]
        );

        alligators.merge(_1st, _2nd, _3rd, msg.sender);
        
        _mergePrize(msg.sender);

        emit mergeFulfilled(alligators.currentMergeId());
    }

    function _mergePrize(address _receiver) internal returns (uint256 requestId) {
        requestId = _vrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrf_requests[requestId] = RequestStatus(
            {
                randomWords: new uint256[](0),
                prize : 0, reciever: _receiver
            });

        emit RequestSent(requestId, NUM_WORDS);

        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        vrf_requests[_requestId].randomWords = _randomWords;

        uint moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;

        uint256[2] memory chanceArracy = getChanceArray();

        if (moddedRng > chanceArracy[0]) {
            // withdraw from tax treasury to the reciever. !!!
            address payable to = payable(vrf_requests[_requestId].reciever);
            to.transfer(_calculatePortionToDistribute());
            emit mergePrizeStatus(true);
        }
        emit RequestFulfilled(_requestId, _randomWords);
    }


    function _compareTrait(uint256 _1st, uint256 _2nd, uint256 _3rd, uint8 _index) internal returns (uint8[2] memory value_) {
        if (alligators.traitLevels(_1st)[_index] >= alligators.traitLevels(_2nd)[_index]) {
            if (alligators.traitLevels(_1st)[_index] >= alligators.traitLevels(_3rd)[_index]) {
                // first value is Type index, second one is Level Index
                uint8[2] memory value_ = [alligators.anatomy(_1st)[_index], alligators.traitLevels(_1st)[_index]];
                return value_;
            } else {
                uint8[2] memory value_ = [alligators.anatomy(_3rd)[_index], alligators.traitLevels(_3rd)[_index]];
                return value_;
            }
        } else {
            if (alligators.traitLevels(_2nd)[_index] >= alligators.traitLevels(_3rd)[_index]) {
                uint8[2] memory value_ = [alligators.anatomy(_2nd)[_index], alligators.traitLevels(_2nd)[_index]];
                return value_;
            } else {
                uint8[2] memory value_ = [alligators.anatomy(_3rd)[_index], alligators.traitLevels(_3rd)[_index]];
                return value_;
            }
        }
    }

    function _compareTraitJoker(uint256 _2nd, uint256 _3rd, uint8 _index) internal returns (uint8[2] memory value_) {
        if (alligators.traitLevels(_2nd)[_index] >= alligators.traitLevels(_3rd)[_index]) {

            uint8[2] memory value_ = [alligators.anatomy(_2nd)[_index], alligators.traitLevels(_2nd)[_index]];
            return value_;

        } else {

            uint8[2] memory value_ = [alligators.anatomy(_3rd)[_index], alligators.traitLevels(_3rd)[_index]];
            return value_;

        }
    }

    //

    function _getBalance() internal view returns (uint256) {
        address payable self = payable(address(this));
        uint256 balance = self.balance;
        return balance;
    }

    function _calculatePortionToDistribute() internal view returns (uint256) {
        return _getBalance() * _prizeBps / 10_000;
    }

    function _calculatePortionToRewardPool() internal view returns (uint256) {
        return _taxAmount * _prizePortionBps / 10_000;
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }
    //
    function getChanceArray() public view returns (uint256[2] memory) {
        return [MIN_CHANCE_VALUE, MAX_CHANCE_VALUE];
    }

    function setChanceArray(uint256 _min) external onlyOwner {
        require(_min < MAX_CHANCE_VALUE, "invalid");
        MIN_CHANCE_VALUE = _min;
    }

    function setTaxAmount(uint256 taxAmount) external onlyOwner {
        _taxAmount = taxAmount;
    }

    function setPortion(uint256 taxAmount) external onlyOwner {
        _taxAmount = taxAmount;
    }

    function setTreasuryAddress(address payable _taxTreasuryAddress) external onlyOwner {
        taxTreasury = _taxTreasuryAddress;
    }
    
    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        _rescueTo.transfer(_amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ______     __         __         __     ______     ______     ______   ______     ______     ______    
// /\  __ \   /\ \       /\ \       /\ \   /\  ___\   /\  __ \   /\__  _\ /\  __ \   /\  == \   /\  ___\   
// \ \  __ \  \ \ \____  \ \ \____  \ \ \  \ \ \__ \  \ \  __ \  \/_/\ \/ \ \ \/\ \  \ \  __<   \ \___  \  
//  \ \_\ \_\  \ \_____\  \ \_____\  \ \_\  \ \_____\  \ \_\ \_\    \ \_\  \ \_____\  \ \_\ \_\  \/\_____\ 
//   \/_/\/_/   \/_____/   \/_____/   \/_/   \/_____/   \/_/\/_/     \/_/   \/_____/   \/_/ /_/   \/_____/ 

import './interface/IAlligators.sol';
import './extension/Royalty.sol';
import './extension/Ownable.sol';
import './extension/ERC165.sol';
import './extension/ContractMetadata.sol';
import './interface/IERC721Receiver.sol';
import './chainlink/VRFConsumerBaseV2.sol';
import './chainlink/VRFCoordinatorV2Interface.sol';
import './utils/Strings.sol';
import './utils/Counters.sol';
import './utils/Address.sol';

contract Alligators is
    IAlligators,
    ERC165,
    Ownable,
    Royalty,
    ContractMetadata,
    VRFConsumerBaseV2 {
        
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private MergeIds;
    Counters.Counter private AlligatorIds;
    Counters.Counter private JokerIds;
    Counters.Counter private WLCounter;
    Counters.Counter private RandomCounter;

    //COLLECTION SIZES
    uint constant ALLIGATORS_LIMIT = 10000;
    uint constant JOKER_LIMIT = 1000;
    
    address public mergeHub;

    //LIMITS
    uint public PER_PUBLIC = 5;
    uint public PER_WL = 20;
    uint public WL_LIMIT = 999;


    // =============================================================
    //                            STORAGE
    // =============================================================

    uint256 internal _currentIndex;
    uint256 internal _burnCounter;

    uint256 public mintPay = 0;

    string private _name;
    string private _symbol;
    string private _baseMetaDataURL;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;
    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // 0 for off - 1 for on
    mapping(address => uint) public isWhitelisted;
    mapping(address => uint) private _whitelistMintedCount;
    
    mapping(uint256 => RequestStatus) private vrf_requests; /* requestId --> requestStatus */

    mapping(uint256 => uint8) private tokenIdType;
    mapping(uint256 => NFT_Anatomy) internal _anatomy;
    mapping(uint256 => NFT_LEVEL) internal _lvl;
    mapping(uint256 => uint8) internal JOKERLvl;

    mapping(uint256 => string) private _tokenURIs;

    // ========================== VRF ===================================

    VRFCoordinatorV2Interface private immutable vrfCoordinatorG;
    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit = 1000000;
    uint32 private constant NUM_WORDS = 10;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable gasLane;
    uint256 internal constant MAX_CHANCE_VALUE = 10000;
    uint256 internal MIN_CHANCE_VALUE = 8888;

    // MergeHub Modifier
    modifier onlyMerger{
        require(msg.sender == mergeHub);
        _;
    }

    SaleStatus public saleStatus = SaleStatus.PRESALE;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint64 subscriptionId_,
        address vrfCoordinatorV2_,
        bytes32 gasLane_,
        address payable royaltyRecipient_,
        uint256 royaltyBPS_
    )VRFConsumerBaseV2(vrfCoordinatorV2_)
    {
        _name = name_;
        _symbol = symbol_;

        _currentIndex = _startTokenId();

        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(royaltyRecipient_, royaltyBPS_);

        subscriptionId = subscriptionId_;
        vrfCoordinatorG = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
        gasLane = gasLane_;
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

   /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
     function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) public view override returns (uint256) {
        if (owner_ == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner_].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner_) internal view returns (uint256) {
        return uint256(_addressData[owner_].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner_) internal view returns (uint256) {
        return uint256(_addressData[owner_].numberBurned);
    }

    // =============================================================
    //                      OWNERSHIP OPERATIONS
    // =============================================================

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    TokenOwnership memory ownership = _ownerships[curr];
                    if (!ownership.burned) {
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        while (true) {
                            curr--;
                            ownership = _ownerships[curr];
                            if (ownership.addr != address(0)) {
                                return ownership;
                            }
                        }
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        if (!_exists(tokenId)) revert callErr();
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        // Our servers URL
        return "https://www.our.server/";
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev See {IERC721-approve}.
     */
     function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        if (to == owner_) revert ApprovalToCurrentOwner();

        if (_msgSenderIn() != owner_)
            if (!isApprovedForAll(owner_, _msgSenderIn())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _approve(to, tokenId, owner_);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderIn()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderIn()][operator] = approved;
        emit ApprovalForAll(_msgSenderIn(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract())
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection.
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderIn() == from ||
            isApprovedForAll(from, _msgSenderIn()) ||
            getApproved(tokenId) == _msgSenderIn());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderIn() == from ||
                isApprovedForAll(from, _msgSenderIn()) ||
                getApproved(tokenId) == _msgSenderIn());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner_
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSenderIn(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {
        if (saleStatus == SaleStatus.PAUSED) revert callErr();
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}


    function _msgSenderIn() internal view virtual returns (address) {
        return msg.sender;
    }

    // =============================================================
    //                      ********__********
    // =============================================================

    /*
        <<MERGE>>
    */

    function merge(uint256 _1st, uint256 _2nd, uint256 _3rd, address _owner) external onlyMerger {

        if (ownerOf(_1st) != _owner || ownerOf(_2nd) != _owner || ownerOf(_3rd) != _owner ) revert callErr();
        //generate merged token
        tokenIdType[_currentIndex] = 3;

        _setTokenURI(_currentIndex, Strings.toString(_currentIndex));

        _mint(_owner, 1);

        MergeIds.increment(1);

        // burn them all
        if (tokenIdType[_1st] == 3) {
            _burn(_2nd);
            _burn(_3rd);
        } else {
            _burn(_1st);
            _burn(_2nd);
            _burn(_3rd);
        }

    }

    function createSkeleton(uint8 _trait1, uint8 _trait2, uint8 _trait3, uint8 _trait4, uint8 _trait5, uint8 _trait6, uint8 _trait7) external onlyMerger {
        _anatomy[_currentIndex] = NFT_Anatomy(
            {
                trait1: Trait1(_trait1), 
                trait2: Trait2(_trait2),
                trait3: Trait3(_trait3),
                trait4: Trait4(_trait4),
                trait5: Trait5(_trait5),
                trait6: Trait6(_trait6),
                trait7: Trait7(_trait7)
            });
    }

    function createLevels(uint8 _trait1, uint8 _trait2, uint8 _trait3, uint8 _trait4, uint8 _trait5, uint8 _trait6, uint8 _trait7) external onlyMerger {
        _lvl[_currentIndex] = NFT_LEVEL(
            {
                trait1Lvl: Level(_trait1), 
                trait2Lvl: Level(_trait2),
                trait3Lvl: Level(_trait3),
                trait4Lvl: Level(_trait4),
                trait5Lvl: Level(_trait5),
                trait6Lvl: Level(_trait6),
                trait7Lvl: Level(_trait7)
            });
    }

    // =============================================================
    //                   Minting + Randomness OPERATIONS
    // =============================================================

    function publicMint() public payable {

        require(msg.value >= mintPay, "unfulfilled pay");

        if (saleStatus == SaleStatus.PAUSED) revert callErr();

        if (saleStatus == SaleStatus.PRESALE) revert callErr();

        if (balanceOf(msg.sender) >= PER_PUBLIC) revert callErr();

        VRFMint(msg.sender);
    }

    function VRFMint(address to) internal returns (uint256 requestId) {
        requestId = vrfCoordinatorG.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrf_requests[requestId] = RequestStatus(
            {
                randomWords: new uint256[](0),
                jokerMint: 0, jokerMintPrize: 0,
                sender: to
            });
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }  

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {

        vrf_requests[_requestId].randomWords = _randomWords;

        address publicMinter = vrf_requests[_requestId].sender;

        uint256 moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;
        uint256 moddedRngPrize = _randomWords[1] % MAX_CHANCE_VALUE;

        uint256[2] memory chanceArracy = getChanceArray();

        if (saleStatus == SaleStatus.PUBLIC || saleStatus == SaleStatus.PRESALE) {

            if (moddedRng < chanceArracy[0]) {
                vrf_requests[_requestId].jokerMint = 0;
                alligatorMint(publicMinter, _requestId);

            } else {
                vrf_requests[_requestId].jokerMint = 1;
                jokerMint(publicMinter, _requestId);
            }
        }

        if (saleStatus == SaleStatus.COMMON_SUPPLIED) {

            vrf_requests[_requestId].jokerMint = 1;
            jokerMint(publicMinter, _requestId);

        }

        if (saleStatus == SaleStatus.JOKER_SUPPLIED) {

            vrf_requests[_requestId].jokerMint = 0;
            alligatorMint(publicMinter, _requestId);

        }

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function alligatorMint(address to, uint256 _requestId) internal {

        if (AlligatorIds.current() > ALLIGATORS_LIMIT) revert callErr();

        uint256[] memory _randomWords = vrf_requests[_requestId].randomWords;

        Trait1 type1 = Trait1(_randomWords[2] % 3);
        Trait2 type2 = Trait2(_randomWords[3] % 3);
        Trait3 type3 = Trait3(_randomWords[4] % 3);
        Trait4 type4 = Trait4(_randomWords[5] % 3);
        Trait5 type5 = Trait5(_randomWords[6] % 3);
        Trait6 type6 = Trait6(_randomWords[7] % 3);
        Trait7 type7 = Trait7(_randomWords[8] % 3);
        
        _anatomy[_currentIndex] = NFT_Anatomy(
            {
                trait1: type1, 
                trait2: type2,
                trait3: type3,
                trait4: type4,
                trait5: type5,
                trait6: type6,
                trait7: type7
            });
        _lvl[_currentIndex] = NFT_LEVEL(
            {
                trait1Lvl: Level.L1,
                trait2Lvl: Level.L1,
                trait3Lvl: Level.L1,
                trait4Lvl: Level.L1,
                trait5Lvl: Level.L1,
                trait6Lvl: Level.L1,
                trait7Lvl: Level.L1
            });

        // 1 for alligators, 2 for generated from merge and 3 for JOKERs
        tokenIdType[_currentIndex] = 1;

        _mint(to, 1);
           
        _setTokenURI(_currentIndex - 1, Strings.toString(_currentIndex - 1));

        AlligatorIds.increment(1);        
    }

    function jokerMint(address to, uint256 _requestId) internal {

        if (JokerIds.current() > JOKER_LIMIT) revert callErr();
        
        uint256[] memory _randomWords = vrf_requests[_requestId].randomWords;
        
        // JOKER's level will be randomize from 1 to 4;
        JOKERLvl[_currentIndex] = uint8(_randomWords[9] % 3) + 1;

        // 1 for alligators, 2 for generated from merge and 3 for JOKERs
        tokenIdType[_currentIndex] = 3;

        _mint(to, 1);

        _setTokenURI(_currentIndex - 1, Strings.toString(_currentIndex - 1));

        JokerIds.increment(1);
    }

    function whitelistMint() public {  

        if (saleStatus == SaleStatus.PAUSED) revert callErr();

        if (saleStatus == SaleStatus.PRESALE || saleStatus == SaleStatus.PUBLIC) {
            //check coupon
            verify(msg.sender);
            //check limits - per wallet
            if (_whitelistMintedCount[msg.sender] >= PER_WL) revert callErr();
            //check limits - WL sale allowance
            if (WLCounter.current() >= WL_LIMIT) revert callErr();

            _whitelistMintedCount[msg.sender]++;

            VRFMint(msg.sender);

            WLCounter.increment(1);
        }
    }

    /*
        <<PUBLIC GETTERS>>
    */

    function currentMergeId() public view returns (uint256) {
        return MergeIds.current();
    }

    function currentJokerId() public view returns (uint256) {
        return JokerIds.current();
    }

    function currentAlligatorId() public view returns (uint256) {
        return AlligatorIds.current();
    }


    function alligatorsTotalSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return AlligatorIds.current() - _burnCounter;
        }
    }

    function getChanceArray() public view returns (uint256[2] memory) {
        return [MIN_CHANCE_VALUE, MAX_CHANCE_VALUE];
    }

    function anatomy(
        uint256 _tokenId
    ) external view returns (uint8[7] memory _traits) {

        if (_tokenId >= _currentIndex) revert callErr();
        if (tokenIdType[_tokenId] == 3) revert callErr();

        
        NFT_Anatomy memory skeleton = _anatomy[_tokenId];

        return [uint8(skeleton.trait1), uint8(skeleton.trait2), uint8(skeleton.trait3), uint8(skeleton.trait4), uint8(skeleton.trait5), uint8(skeleton.trait6), uint8(skeleton.trait7)];

    }

    function traitLevels(
        uint256 _tokenId
    ) external view returns (uint8[7] memory _traits) {

        if (_tokenId >= _currentIndex) revert callErr();
        if (tokenIdType[_tokenId] == 3) revert callErr();
        
        NFT_LEVEL memory lvls = _lvl[_tokenId];

        return [uint8(lvls.trait1Lvl), uint8(lvls.trait2Lvl), uint8(lvls.trait3Lvl), uint8(lvls.trait4Lvl), uint8(lvls.trait5Lvl), uint8(lvls.trait6Lvl), uint8(lvls.trait7Lvl)];

    }


    function tokenType(
        uint256 _tokenId
    ) external view returns (uint8 _type) {

        if (_tokenId >= _currentIndex) revert callErr();
        
        uint8 _type = tokenIdType[_tokenId];

        return _type;

    }
    
    function JokerLevel(
        uint256 _tokenId
    ) external view returns (uint8 _level) {

        if (_tokenId >= _currentIndex) revert callErr();
        if (tokenIdType[_tokenId] != 3) revert callErr();
        
        uint8 _level = JOKERLvl[_tokenId];

        return _level;

    }

    /* OWNER METHODS
    Setters
    */

    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    function setMergeHub(address mergeHub_) external onlyOwner {
        if (mergeHub_ == address(0)) revert callErr();
        mergeHub = mergeHub_;
        emit mergeIsSet(mergeHub_);
    }

    function setCollectionSizeWL(uint size) external onlyOwner {
        if (size > 1200) revert callErr();
        WL_LIMIT = size;
        emit mintLimitIsSet(size);
    }

    function setPerPersonLimitWL(uint size) external onlyOwner {
        if (size > 50) revert callErr();
        PER_WL = size;
        emit mintLimitIsSet(size);
    }

    function setPerPersonLimitPubic(uint size) external onlyOwner {
        if (size > 10) revert callErr();
        PER_PUBLIC = size;
        emit mintLimitIsSet(size);
    }

    function setChanceArray(uint256 _min) external onlyOwner {
        if (_min > MAX_CHANCE_VALUE) revert callErr();
        MIN_CHANCE_VALUE = _min;
        emit chanceIsSet(_min);
    }

    function addWLAddress(address[] memory _whitelisted) external onlyOwner {
        for (uint index = 0; index < _whitelisted.length; index++) {
            address added = _whitelisted[index];
            isWhitelisted[added] = 1;
        }
    }

    function setBaseURI(string memory _base) external onlyOwner {
        _baseMetaDataURL = _base;
    }

    function setMintPay(uint256 _mintPay) external onlyOwner {
        mintPay = _mintPay;
    }

    /*
        <<INTERNAL>>
    */

    function verify(address whitelisted) internal virtual {
        require(isWhitelisted[whitelisted] == 1, "Invalid signer" );
    }

    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        _rescueTo.transfer(_amount);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

pragma solidity ^0.8.4;

interface IMergeGators {
    
    struct NFT_Anatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFT_LEVEL {
        Level trait1Lvl;
        Level trait2Lvl;
        Level trait3Lvl;
        Level trait4Lvl;
        Level trait5Lvl;
        Level trait6Lvl;
        Level trait7Lvl;
    }

    enum Level {
        L0,
        L1,
        L2,
        L3,
        L4,
        L5
    }

    enum lvlUp {
        FALSE,
        TRUE
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }


    struct RequestStatus {
        uint256[] randomWords;
        uint prize;
        address reciever;
    }

    event mergeRequested(uint256 _1st, uint256 _2nd, uint256 _3rd, address _owner);
    event mergeFulfilled(uint256 mergeId);
    event mergePrizeStatus(bool success);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    error Mergefailed();
}

pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC721Metadata.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IAlligators is IERC721, IERC721Metadata {

    enum Level {
        L0,
        L1,
        L2,
        L3,
        L4,
        L5
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }

    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC,
        JOKER_SUPPLIED,
        COMMON_SUPPLIED,
        ALL_SUPPLIED
    }

   struct NFT_Anatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFT_LEVEL {
        Level trait1Lvl;
        Level trait2Lvl;
        Level trait3Lvl;
        Level trait4Lvl;
        Level trait5Lvl;
        Level trait6Lvl;
        Level trait7Lvl;
    }

    struct RequestStatus {
        uint256[] randomWords;
        // 0 for off || 1 for on
        uint jokerMint;
        // 0 for off || 1 for on
        uint jokerMintPrize;
        address sender;
    }

    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    //function merge(uint256 _1st, uint256 _2nd, uint256 _3rd, address _ownenr) external onlyMerger;
    
    event NftRequested(uint256 indexed requestId, address requester);
    event NftFullfilled(uint256 indexed requestId, address requester, uint256[] randomWords,  bool jokerMint,bool jokerMintPrize, uint256 quantity);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event Verified(address indexed user);
    event mergeIsSet(address mergeHub);
    event chanceIsSet(uint256 value);
    event mintLimitIsSet(uint value);
    event WLAddrIsSet(address[] _whitelisted);
    error InvalidSigner();
    error RangeOutOfBounds();
    error callErr();
    error Mergefailed();
    error invalidSigner();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/IRoyalty.sol";


// The `Royalty` contract is ERC2981 compliant.

abstract contract Royalty is IRoyalty {
    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /**
     *  @notice   View royalty info for a given token and sale price.
     *  @dev      Returns royalty amount and recipient for `tokenId` and `salePrice`.
     *  @param tokenId          The tokenID of the NFT for which to query royalty info.
     *  @param salePrice        Sale price of the token.
     *
     *  @return receiver        Address of royalty recipient account.
     *  @return royaltyAmount   Royalty amount calculated at current royaltyBps value.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / 10_000;
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     *  @notice Returns the defualt royalty recipient and BPS for this contract's NFTs.
     */
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /**
     *  @notice         Updates default royalty recipient and bps.
     *  @dev            Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.
     *
     *  @param _royaltyRecipient   Address to be set as default royalty recipient.
     *  @param _royaltyBps         Updated royalty bps.
     */
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setupDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) internal {
        if (_royaltyBps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /**
     *  @notice         Updates default royalty recipient and bps for a particular token.
     *  @dev            Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.
     *
     *  @param _recipient   Address to be set as royalty recipient for given token Id.
     *  @param _bps         Updated royalty bps for the token Id.
     */
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setupRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (_bps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "../interface/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/IContractMetadata.sol";

/**
 *  @title   Contract Metadata
 *  
 *         s `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter, uint256 _quantity) internal {
        unchecked {
            counter._value += _quantity;
        }
    }

    function decrement(Counter storage counter,uint256 _quantity) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - _quantity;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * [EIP1884](https://eips.ethereum.org/EIPS/eip-1884) increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function getApproved(uint256 tokenId) external view returns (address);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC2981.sol";

interface IRoyalty is IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
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
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}