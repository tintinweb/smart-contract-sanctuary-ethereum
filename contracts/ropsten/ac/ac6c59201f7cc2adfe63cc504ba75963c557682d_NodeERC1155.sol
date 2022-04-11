// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/INodeERC1155.sol";
import "./interfaces/IJoePair.sol";
import "./interfaces/ICorkToken.sol";
import "./interfaces/ISwapCork.sol";
//import "hardhat/console.sol";

contract NodeERC1155 is ERC1155Upgradeable, INodeERC1155, OwnableUpgradeable, ReentrancyGuardUpgradeable  {
    using SafeMathUpgradeable  for uint256;

    bool public isPresaleActive;
    bool public isTradeActive;
    bool public traderJoeDivideSide;
    address payable public manager;
    address public pairAddress;
    address public corkAddress;
    address public swapAddress;
    uint256 private _percentRate;
    uint256 private _currentTokenID;
    uint256 private _rewardInterval;
    uint256 private _periodDays;
    uint256 public claimFeePercentage;

    struct CollectionStruct {
        string title;
        uint256 price;
        uint256 maxSupply;
        uint256 firstRun;
        uint256 trueYield;
        uint256 snowball;
        uint256 maxSnowball;
        uint256 maxDailySell;
        uint256 currentSupply;
        uint256 purchaseLimit;
    }

    // all collection(slope) info
    CollectionStruct[] public collection;

    // 0: Blue, 1: Red, 2: Black, 3: DoubleBlack
    struct NodeStruct {
        address purchaser;
        uint256 nodeType;
        uint256 purchasedAt;
        uint256 snowballAt;
        uint256 claimedSnowball; // only need to get total claimed amount in frontend.
        uint256 remainClaimedAmounts;
        string uri;
    }

    // mapping from tokenId to NodeStruct
    mapping(uint256 => NodeStruct) public nodeState;
    // mapping form owner to node IDs
    mapping(address => uint256[]) public ownedNodes;
    // mapping for blacklist
    mapping(address => bool) public blacklist;

    modifier Blacklist() {
        require(blacklist[_msgSender()] == false, "you're blacklisted");
        _;
    }


    function initialize() initializer public {
        __Ownable_init();
        __ERC1155_init("https://example.com/{id}.json");
        nodeInit();
        _percentRate = 10**8;
        _rewardInterval = 1 days;
        _periodDays = 30;
        claimFeePercentage = 10;
    }

    function setManager(address _manager) public onlyOwner {
        manager = payable(_manager);
    }

    // Function to withdraw all AVAX from this contract.
    function withdraw() public nonReentrant {
        // get the amount of AVAX stored in this contract
        require(_msgSender() == manager, "only manager can call withdraw");
        uint256 amount = address(this).balance;

        // send all AVAX to manager
        // manager can receive AVAX since the address of manager is payable
        (bool success, ) = manager.call{value: amount}("");
        require(success, "Failed to send AVAX");
    }

    // set claim fee percentage
    function setClaimFeePercentage(uint256 nClaimFeePercentage) public onlyOwner {
        claimFeePercentage = nClaimFeePercentage;
    }

    // Function to withdraw cork from this contract.
    function withdrawCork(uint256 amount) public nonReentrant onlyOwner {
        ICorkToken(corkAddress).transfer(_msgSender(), amount);
    }

    function nodeInit() internal {
        collection.push(
            CollectionStruct(
                "Blue",         // title
                4 ether,        // price
                30000,          // maxSupply
                1500000,        // firstRun
                350000,         // trueYield
                1700,           // snowball
                50000,          // maxSnowball
                15000000,       // maxDailySell
                0,              // currentSupply
                30              // purchaseLimit
            )
        );
        collection.push(
            CollectionStruct(
                "Red",          // title
                10 ether,       // price
                15000,          // maxSupply
                2000000,        // firstRun
                900000,         // trueYield
                3333,           // snowball
                100000,         // maxSnowball
                10000000,       // maxDailySell
                0,              // currentSupply
                30              // purchaseLimit
            )
        );
        collection.push(
            CollectionStruct(
                "Black",        // title
                100 ether,      // price
                5000,           // maxSupply
                2200000,        // firstRun
                1000000,        // trueYield
                3333,           // snowball
                100000,         // maxSnowball
                5000000,        // maxDailySell
                0,              // currentSupply
                30              // purchaseLimit
            )
        );
        collection.push(
            CollectionStruct(
                "DoubleBlack",  // title
                1000 ether,     // price
                1000,           // maxSupply
                2200000,        // firstRun
                1000000,        // trueYield
                4167,           // snowball
                125000,         // maxSnowball
                5000000,        // maxDailySell
                0,              // currentSupply
                10              // purchaseLimit
            )
        );
    }

    





    /* Mint Functions */

    function mint(uint256 _nodeType, uint256 _amount, string calldata _uri) public Blacklist {
        require(
            collection[_nodeType].currentSupply <=
                collection[_nodeType].maxSupply,
            "all of this collection are purchased"
        );

        require(
            collection[_nodeType].currentSupply + _amount <=
                collection[_nodeType].maxSupply,
            "there is not enought nodes to sell"
        );

        require(
            getOwnedNodeCountByType(_msgSender(), _nodeType) <
                collection[_nodeType].purchaseLimit,
            "minted nodes exceed amount limit"
        );

        require(
            getOwnedNodeCountByType(_msgSender(), _nodeType) + _amount <
                collection[_nodeType].purchaseLimit,
            "you will exceed nodes amount limit"
        );

        ICorkToken corkToken = ICorkToken(corkAddress);
        if(isPresaleActive){
            require(
                isPresaleActive && corkToken.balanceOf(_msgSender()) >= collection[_nodeType].price * _amount / 2,
                "receiver's balance is less than node price"
            );
        } else {
            require(
                !isPresaleActive && corkToken.balanceOf(_msgSender()) >= collection[_nodeType].price * _amount,
                "receiver's balance is less than node price"
            );
        }
        
        if(isPresaleActive){
            corkToken.transferFrom(
            _msgSender(),
            address(this),
            collection[_nodeType].price * _amount / 2
            );
        } else {
            corkToken.transferFrom(
            _msgSender(),
            address(this),
            collection[_nodeType].price * _amount
            );
        }

        for (uint256 i = 0; i < _amount; i++) {
            uint256 _id = _getNextTokenID();
            _incrementTokenID();
            nodeState[_id].purchaser = _msgSender();
            nodeState[_id].nodeType = _nodeType;
            nodeState[_id].purchasedAt = block.timestamp;
            nodeState[_id].snowballAt = block.timestamp;
            nodeState[_id].uri = _uri;
            if (bytes(_uri).length > 0) {
                emit URI(_uri, _id);
            }
            ownedNodes[_msgSender()].push(_id);
        }

        collection[_nodeType].currentSupply += _amount;
        
        _mint(_msgSender(), _nodeType, _amount, "");
    }

    function mintTo(address to, uint256 _nodeType, uint amount, string calldata _uri) public onlyOwner{
        require(
            collection[_nodeType].currentSupply <=
                collection[_nodeType].maxSupply,
            "all of this collection are purchased"
        );

        require(
            collection[_nodeType].currentSupply + amount <=
                collection[_nodeType].maxSupply,
            "there is not enought nodes to sell"
        );

        require(
            getOwnedNodeCountByType(_msgSender(), _nodeType) <
                collection[_nodeType].purchaseLimit,
            "minted nodes exceed amount limit"
        );

        require(
            getOwnedNodeCountByType(_msgSender(), _nodeType) + amount <
                collection[_nodeType].purchaseLimit,
            "you will exceed nodes amount limit"
        );
        
        _mint(to, _nodeType, amount, "");

        for (uint i = 0; i < amount; i++){
            uint256 _id = _getNextTokenID();
            _incrementTokenID();
            nodeState[_id].purchaser = to;
            nodeState[_id].nodeType = _nodeType;
            nodeState[_id].purchasedAt = block.timestamp;
            nodeState[_id].snowballAt = block.timestamp;
            nodeState[_id].uri = _uri;

            if (bytes(_uri).length > 0) {
                emit URI(_uri, _id);
            }

            ownedNodes[to].push(_id);
        }
        
        collection[_nodeType].currentSupply += amount;
    }

    function bailOutMint(
        uint256 id, // node used in bailout mint
        uint256 nodeType,
        uint256 amount, // bailout mint amount
        string calldata _uri
    ) public Blacklist {
        require(
            nodeState[id].purchaser == _msgSender(),
            "only node owner can use it"
        );
        uint256 claimableCork = getClaimableCorkById(id);
        uint256 wastedCork = collection[nodeType].price * amount;

        require(
            claimableCork >= wastedCork,
            "claimable cork is less than price"
        );

        require(
            collection[nodeType].currentSupply <=
                collection[nodeType].maxSupply,
            "all of this collection are purchased"
        );

        require(
            getOwnedNodeCountByType(_msgSender(), nodeType) <
                collection[nodeType].purchaseLimit,
            "minted nodes exceed amount limit"
        );

        (, uint256 snowballRewardCork) = calculateClaimableAmount(id);
        nodeState[id].snowballAt = block.timestamp;
        if (wastedCork < claimableCork) {
            nodeState[id].remainClaimedAmounts = claimableCork - wastedCork;
        }
        nodeState[id].claimedSnowball += snowballRewardCork;

        _mint(_msgSender(), nodeType, amount, "");

        for (uint256 i = 0; i < amount; i++) {
            uint256 _id = _getNextTokenID();
            _incrementTokenID();
            nodeState[_id].purchaser = _msgSender();
            nodeState[_id].nodeType = nodeType;
            nodeState[_id].purchasedAt = block.timestamp;
            nodeState[_id].snowballAt = block.timestamp;
            nodeState[_id].uri = _uri;

            if (bytes(_uri).length > 0) {
                emit URI(_uri, _id);
            }

            ownedNodes[_msgSender()].push(_id);
        }
        collection[nodeType].currentSupply+= amount;
    }



    /* Trade Functions */

    function setTradeActivate(bool active) onlyOwner public {
        isTradeActive = active;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual Blacklist override {
        require(isTradeActive == true, "Node: Transfer is disabled");

        super.safeTransferFrom(from, to, id, amount, data);

        uint256 count;
        for (uint256 i = 0; i < ownedNodes[from].length; i++) {
            if (nodeState[ownedNodes[from][i]].nodeType == id) {

                /* Claim Part */
                ICorkToken corkToken = ICorkToken(corkAddress);

                (uint256 mainRewardCork, uint256 snowballRewardCork) = calculateClaimableAmount(ownedNodes[from][i]);

                nodeState[ownedNodes[from][i]].snowballAt = block.timestamp;
                nodeState[ownedNodes[from][i]].claimedSnowball += snowballRewardCork;
                uint256 claimableCork = (snowballRewardCork + mainRewardCork);
                corkToken.transfer(from, claimableCork);

                nodeState[ownedNodes[from][i]].purchaser = to;

                /* Transfer Part */
                ownedNodes[to].push(ownedNodes[from][i]);
                delete ownedNodes[from][i];
                count ++;
                if (count >= amount) break;
            }
        }
    }



    /* Claim Functions */

    function claim() external payable Blacklist nonReentrant {
        require(ownedNodes[_msgSender()].length > 0, "No have a node");
        require(getClaimFee(_msgSender()) <= msg.value, "No fee is set");
        ICorkToken corkToken = ICorkToken(corkAddress);
        uint256 claimableCork;

        for (uint256 i = 0; i < ownedNodes[_msgSender()].length; i++) {
            uint256 id = ownedNodes[_msgSender()][i];

            // mainRewardCork: first run yield and true yield
            // snowballRewardCork; sonwball effect yield
            (
                uint256 mainRewardCork,
                uint256 snowballRewardCork
            ) = calculateClaimableAmount(id);
            nodeState[id].snowballAt = block.timestamp;
            nodeState[id].claimedSnowball += snowballRewardCork;
            nodeState[id].remainClaimedAmounts = 0;
            claimableCork += (snowballRewardCork + mainRewardCork);
        }

        corkToken.transfer(_msgSender(), claimableCork);
    }

    function claimPartial(uint256 amountMax, uint256 id) external payable Blacklist nonReentrant {
        require(ownedNodes[_msgSender()].length > 0, "No have a node");
        require(nodeState[id].purchaser == _msgSender(), "only puchaser can claim");
        require(getClaimFeeByValue(amountMax) <= msg.value, "No fee is set");
        
        ICorkToken corkToken = ICorkToken(corkAddress);

        uint256 claimableCork;

        // mainRewardCork: first run yield and true yield
        // snowballRewardCork; sonwball effect yield
        (uint256 mainRewardCork, uint256 snowballRewardCork) = calculateClaimableAmount(id);

        uint256 claimAmount = snowballRewardCork + mainRewardCork;
        require(claimAmount >= amountMax, "You don't have much in your node");

        uint256 patialRatio = ((amountMax - claimableCork) * (_percentRate)) / claimAmount;

        claimableCork += claimAmount * patialRatio / _percentRate;
        nodeState[id].snowballAt = block.timestamp;
        nodeState[id].claimedSnowball += snowballRewardCork * patialRatio / _percentRate;
        nodeState[id].remainClaimedAmounts = mainRewardCork - (mainRewardCork * patialRatio / _percentRate);
        
        corkToken.transfer(_msgSender(), claimableCork);
    }

    function claimById(uint256 id) external payable Blacklist nonReentrant {
        require(
            nodeState[id].purchaser == _msgSender(),
            "only puchaser can claim"
        );
        require(getClaimFeeById(id) <= msg.value, "No set enough fee");
        ICorkToken corkToken = ICorkToken(corkAddress);

        (
            uint256 mainRewardCork,
            uint256 snowballRewardCork
        ) = calculateClaimableAmount(id);
        nodeState[id].snowballAt = block.timestamp;
        nodeState[id].claimedSnowball += snowballRewardCork;
        nodeState[id].remainClaimedAmounts = 0;
        uint256 claimableCork = (snowballRewardCork + mainRewardCork);

        corkToken.transfer(_msgSender(), claimableCork);
    }

    

    function getClaimableCork(address claimAddress)
        public
        view
        returns (uint256)
    {
        require(ownedNodes[claimAddress].length > 0, "No have a node");
        uint256 claimableCork;

        for (uint256 i = 0; i < ownedNodes[claimAddress].length; i++) {
            uint256 id = ownedNodes[claimAddress][i];

            // mainRewardCork: first run yield and true yield
            // snowballRewardCork; sonwball effect yield
            (
                uint256 mainRewardCork,
                uint256 snowballRewardCork
            ) = calculateClaimableAmount(id);

            claimableCork += (snowballRewardCork + mainRewardCork);
        }
        return claimableCork;
    }

    function calculateClaimableAmount(uint256 _id)
        public
        view
        returns (uint256, uint256)
    {
        require(nodeState[_id].purchaser != address(0), "No node exist");
        uint256 _nodeType = nodeState[_id].nodeType;
        uint256 _price = collection[_nodeType].price;

        // lasted days
        uint256 lastedMainDays = (block.timestamp - nodeState[_id].purchasedAt)
            .div(_rewardInterval);
        uint256 lastedSnowballDays = (block.timestamp -
            nodeState[_id].snowballAt).div(_rewardInterval);

        uint256 mainRewardAmount = calculateMainAmount(
            collection[_nodeType].firstRun,
            collection[_nodeType].trueYield,
            lastedMainDays,
            lastedSnowballDays,
            getNodeROI(_nodeType)
        );
        uint256 snowballRewardAmount = calculateSnowballAmount(
            collection[_nodeType].snowball,
            collection[_nodeType].maxSnowball,
            lastedSnowballDays,
            getNodeROI(_nodeType)
        );
        return (
            _amount2cork(mainRewardAmount, _price) + nodeState[_id].remainClaimedAmounts,
            _amount2cork(snowballRewardAmount, _price)
        );
    }

    function calculateMainAmount(
        uint256 _firstRun,
        uint256 _trueYield,
        uint256 _lastedMainDays,
        uint256 _noClaimDays,
        uint256 _roiTime
    ) public pure returns (uint256) {

        // if true yield started
        if (_lastedMainDays > _roiTime) {
            uint256 lastedTrueYieldDays = _lastedMainDays - _roiTime;

            uint256 _Reward;
            if ((_lastedMainDays - _noClaimDays) < _roiTime) {
                _Reward = (_roiTime - (_lastedMainDays - _noClaimDays)) * _firstRun;
                _Reward += _trueYield * lastedTrueYieldDays;
            } else {
                _Reward = _trueYield * _noClaimDays;
            }

            return _Reward;

            //return (lastedTrueYieldDays * _trueYield) + (_lastClaimDate - lastedTrueYieldDays) * _firstRun; // ROI + true yield
        } else {
            return _noClaimDays * _firstRun;
        }
    }

    function calculateSnowballAmount(
        uint256 _snowball,
        uint256 _maxSnowball,
        uint256 _lastedSnowballDays,
        uint256 _roiTime
    ) private view returns (uint256) {
        // if reached at the max snowball
        if (_lastedSnowballDays < _roiTime) {
            uint256 totalRates;
            for (uint256 i = 0; i <= _lastedSnowballDays; i++) {
                totalRates += i;
            }
            return totalRates * _snowball;
        } else {
            uint256 totalRates;
            for (uint256 i = 0; i <= _roiTime; i++) {
                totalRates += i;
            }
            return
                totalRates *
                _snowball + // snowball effect when bumping
                _maxSnowball *
                (_lastedSnowballDays - _periodDays); // max snowball effect
        }
    }

    function sellableCork(address from)
        external
        view
        override
        returns (uint256)
    {
        uint256 _sellableCork;

        for (uint256 i = 0; i < collection.length; i++) {
            if (balanceOf(from, i) > 0) {
                _sellableCork +=
                    balanceOf(from, i) *
                    _amount2cork(
                        collection[i].maxDailySell,
                        collection[i].price
                    );
            }
        }

        return _sellableCork;
    }



    /* Claim fees function */

    function getClaimFee(address claimAddress) public view returns (uint256) {
        uint256 claimableCork = getClaimableCork(claimAddress);
        uint256 corkPrice = getCorkPrice();
        return (claimableCork * corkPrice).div(10**18) * claimFeePercentage / 100;
    }

    function getClaimableCorkById(uint256 id) public view returns (uint256) {
        // mainRewardCork: first run yield and true yield
        // snowballRewardCork; sonwball effect yield
        (uint256 mainRewardCork, uint256 snowballRewardCork) = calculateClaimableAmount(id);
        uint256 claimableCork = (snowballRewardCork + mainRewardCork);
        return claimableCork;
    }

    function getClaimFeeById(uint256 id) public view returns (uint256) {
        uint256 claimableCork = getClaimableCorkById(id);
        uint256 corkPrice = getCorkPrice();
        return (claimableCork * corkPrice).div(10**18) * claimFeePercentage / 100;
    }

    function getClaimFeeByValue(uint256 value) public view returns (uint256) {
        uint256 corkPrice = getCorkPrice();
        return (value * corkPrice).div(10**18) * claimFeePercentage / 100;
    }




    /* Others */

    function updateCollection(
        uint256 id, 
        string memory title,
        uint256 price,
        uint256 maxSupply,
        uint256 firstRun,
        uint256 trueYield,
        uint256 snowball,
        uint256 maxSnowball,
        uint256 maxDailySell,
        uint256 currentSupply,
        uint256 purchaseLimit
    ) public onlyOwner {
        collection[id] = CollectionStruct(title, price, maxSupply, firstRun, trueYield, snowball, maxSnowball, maxDailySell, currentSupply, purchaseLimit);
    }

    function addToCollection(
        string memory title,
        uint256 price,
        uint256 maxSupply,
        uint256 firstRun,
        uint256 trueYield,
        uint256 snowball,
        uint256 maxSnowball,
        uint256 maxDailySell,
        uint256 currentSupply,
        uint256 purchaseLimit
    ) public onlyOwner {
        collection.push(CollectionStruct(title, price, maxSupply, firstRun, trueYield, snowball, maxSnowball, maxDailySell, currentSupply, purchaseLimit));
    }

    function swapTokensForAVAX(uint256 amount) public {
        ISwapCork swap = ISwapCork(swapAddress);
        swap.swapCorkForAVAX(_msgSender(), amount);
    }

    function resetContract(
        address _pairAddress,
        address _corkAddress,
        address _swapAddress
    ) external onlyOwner {
        if (_pairAddress != address(0)) pairAddress = _pairAddress;
        if (_corkAddress != address(0)) corkAddress = _corkAddress;
        if (_swapAddress != address(0)) swapAddress = _swapAddress;
    }

    function setTraderJoeDivideSide(bool side) public onlyOwner {
        traderJoeDivideSide = side;
    }

    // note: when adding pool, res0 : cork, res1: avax
    /* function getCorkPrice() public view returns (uint256) {
        if (traderJoeDivideSide) {
            (uint256 Res1, uint256 Res0, ) = IJoePair(pairAddress).getReserves();
            uint256 price = (Res1 * (10**18)).div(Res0);
            return price;
        } else {
            (uint256 Res0, uint256 Res1, ) = IJoePair(pairAddress).getReserves();
            uint256 price = (Res1 * (10**18)).div(Res0);
            return price;
        }
    }  */

    function getCorkPrice() public view returns (uint256) {
        return 3;
    }

    function getOwnedNodeCountByType(address user, uint256 nodeType)
        public
        view
        returns (uint256)
    {
        uint256 count;
        for (uint256 i = 0; i < ownedNodes[user].length; i++) {
            if (nodeState[ownedNodes[user][i]].nodeType == nodeType) count++;
        }
        return count;
    }

    function getNodeState(uint256 id) public view returns (NodeStruct memory) {
        return nodeState[id];
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID + 1;
    }

    function _incrementTokenID() private {
        _currentTokenID++;
    }

    function _amount2cork(uint256 _amount, uint256 _price)
        private
        view
        returns (uint256)
    {
        return (_amount * _price).div(_percentRate);
    }

    function setPresaleActive(bool _isPresaleActive) public onlyOwner {
        //require(!isPresaleActive, "Presale was already activated");
        isPresaleActive = _isPresaleActive;
    }

    function checkPresaleActive() public view returns (bool) {
        return isPresaleActive;
    }

    function getNodeROI(uint256 id) public view returns (uint256) {
        uint roiByTen = (10 ** 9) / collection[id].firstRun;
        if (roiByTen % 10 != 0) {
            roiByTen = roiByTen + 10 - (roiByTen % 10);
        }
        
        return roiByTen / 10;
    }

    function updateRewardInterval(uint256 _interval) public onlyOwner {
        _rewardInterval = _interval;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface INodeERC1155 {
    function sellableCork(address from) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICorkToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function setApprove(address owner, address spender, uint256 amount) external;

    function transferTax(address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ISwapCork {
    function swapCorkForAVAX(address from, uint256 amount) external;
    function getSwapAvailable() external view returns(bool);
    function removeSwapAvailable() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
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

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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