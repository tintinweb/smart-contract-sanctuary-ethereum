/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IPandaPool.sol";
import "../interfaces/IPoolKit.sol";

/**
 */

contract PandaPoolCore is Ownable, ReentrancyGuard, IERC721Receiver, IPoolKit, IPandaPool {
    using SafeERC20 for IERC20;

    struct BuyCommit {
        bytes32 commit;
        uint64 block;
        bool revealed;
        uint256 amountBuyMax;
        uint256 deadline;
    }

    struct RebornCommit {
        bytes32 commit;
        uint64 block;
        bool revealed;
        uint256 ownerTokenId;
        uint256 amountFeeMax;
        uint256 deadline;
    }

    address immutable public pandaToken;
    address immutable public pandaNFT;
    uint256 public minPoolNFTCount = 1000;

    mapping(address => bool) public admins;

    bool public isPoolOpen = true;
    bool public isCrOpen = true;
    mapping(uint256 => uint256) public poolNftMap;
    mapping(address => BuyCommit) public buyCommits;
    mapping(address => RebornCommit) public rebornCommits;
    mapping(address => bool) public buyCompensates;
    mapping(address => bool) public rebornCompensates;
    uint256 public poolSize = 2000;
    uint256 public poolIndexBase = 1;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant NFT_TOTAL_SUPPLY = 10000;
    uint256 public constant FEE_BASE = 10000;
    uint256 public poolFeeValue = 375;
    uint256 public treasuryFeeValue = 0;


    event Redeem(address indexed recipient, uint256 ownerTokenId, uint256 receiveAmount);
    event AddLiquidity(address indexed recipient, uint256[] supplyTokens, uint256 amountPayToken, uint256 updateMinPoolNftCount);
    event RemoveLiquidity(address indexed recipient, uint256[] targetTokens, uint256 amountReceiveToken, uint256 updateMinPoolNftCount);
    event RemovePoolForUpdate(address indexed recipient, uint256[] targetTokens);
    event AddPoolForSwap(address indexed recipient, uint256[] supplyTokens);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);
    event CommitOwnerBuy(address indexed sender, bytes32 dataHash, uint64 block);    
    event CommitOwnerRebron(address indexed sender, bytes32 dataHash, uint64 block,uint256 ownerTokenId);    
    event OwnerRebornRevealHash(address indexed sender, bytes32 revealHash, uint256 ownerTokenId, uint256 index, uint256 targetIndex);
    event OwnerBuyRevealHash(address indexed sender, bytes32 revealHash, uint256 index, uint256 targetIndex);
    event ResetPandaPool(uint256 size, uint256 poolIndexBase);
    event SwitchEvent(bool poolOpne, bool crOpen);
    event SetPoolFeeValue(uint256 feeValue);
    event SetTreasuryFeeValue(uint256 feeValue);
    event UpdatePandaPool(uint256 updateMinPoolNftCount);

    error OnlyAdminError();
    error TimeOutError(uint256 deadline, uint256 timestamp);
    error ZeroAddrError();
    error PoolCloseError();
    error NFTOwnerNotMatch(uint tokenId, address expectOwner, address realOwner);
    error MaxFeeNotMatch(uint256 maxUserFee, uint256 poolNeedFee);
    error PandaNotEnough(address sender, uint256 balance, uint256 needBalance);
    error PoolNFTTooMany(uint256 poolNftNum, uint256 upLimit);
    error MinReceiveNotMatch(uint256 exceptMinReceive, uint256 poolPayFor);
    error MaxBuyNotMatch(uint256 maxUserPayFor, uint256 poolNeedPayFor);
    error PoolNotEnoughNFT(uint256 poolBalance, uint256 downLimit);
    error UserNotEnoughNFT(address user, uint256 userBalance, uint256 needBalance);
    error PoolIndexNotMatchNFTId(uint256 index, uint256 poolTokeId, uint256 exceptTokenId);
    error TransferEhterFail(address sender, address receiver, uint256 amount);
    error AlreadyRevealedError(address sender);
    error RevealedNotMatchError(bytes32 _hash, bytes32 commit);
    error RevealHappenEarly(uint256 revealTime, uint256 commitTime);
    error RevealTooLate(uint256 revealTime, uint256 lateTime);
    error NotCompensate(address user);
    error PoolArrayIndexOutOfRange(uint256 index, uint256 size);
    error CannotWithdrawPanda();


    modifier onlyAdmin() {
        if(!admins[msg.sender] && msg.sender != owner()) {
            revert OnlyAdminError();
        }
        _;
    }

    modifier ensure(uint deadline) {
        if(deadline < block.timestamp) {
            revert TimeOutError(deadline, block.timestamp);
        }
        _;
    }

    modifier notZeroAddr(address addr_) {
        if(addr_ == ZERO_ADDRESS) {
            revert ZeroAddrError();
        }
        _;
    }

     modifier poolOpen() {
        if(!isPoolOpen) {
            revert PoolCloseError();
        }
        _;
    }

    modifier crOpen() {
        if(!isCrOpen) {
            revert PoolCloseError();
        }
        _;
    }


    

     /**
     * @dev Constructor.
     */
    constructor(
        address _pandaToken,
        address _pandaNft
    )
    {
        pandaToken = _pandaToken;
        pandaNFT = _pandaNft;
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    
//############################ Liquid Functions Start #####################

    /**
     * @dev redeem NFT, you will receive $PANDA.
     * @param _ownerTokenId The NFT Id you want to redeem
     * @param _amountRedeemMin  Less than this value you will not redeem
     * @param _deadline deadline
     */
    function redeem(uint256 _ownerTokenId, uint256 _amountRedeemMin, uint256 _deadline) external override ensure(_deadline) nonReentrant poolOpen {
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(_ownerTokenId) != msg.sender) {
            revert NFTOwnerNotMatch(_ownerTokenId,  msg.sender, _pandaNFT.ownerOf(_ownerTokenId));
        }
        
        uint256 _price = _currentPrice();
        uint256 feeValue = poolFeeValue + treasuryFeeValue;
        if (_amountRedeemMin > _price * (FEE_BASE - feeValue) / FEE_BASE) {
            revert MinReceiveNotMatch(_amountRedeemMin, _price * (FEE_BASE - feeValue) / FEE_BASE);
        }
        _pandaNFT.safeTransferFrom(msg.sender, address(this), _ownerTokenId, "");
        
        IERC20(pandaToken).safeTransfer(msg.sender,  _price * (FEE_BASE - feeValue) / FEE_BASE);
        _poolPushNft(_ownerTokenId);
        emit Redeem(msg.sender, _ownerTokenId, _price * (FEE_BASE - feeValue) / FEE_BASE);
    }


    /**
     * @dev owner addLiquidity.
     * @param _supplyTokens add these NFTs to pool
     * @param _amountTokenMax  Above this value owner will not add liquidity
     * @param _updateMinPoolNftCount update pool min nfts 
     * @param _deadline deadline
     */
    function addLiquidity(uint256[] calldata _supplyTokens, uint256 _amountTokenMax, uint256 _updateMinPoolNftCount, uint256 _deadline) external override ensure(_deadline) onlyOwner nonReentrant {

        uint256 _length = _supplyTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if(_pandaNFT.balanceOf(msg.sender) < _length) {
            revert UserNotEnoughNFT(msg.sender, _pandaNFT.balanceOf(msg.sender), _length);
        }

        IERC20 _pandaToken = IERC20(pandaToken);
        if (_pandaToken.balanceOf(msg.sender) < _amountTokenMax) {
            revert PandaNotEnough(msg.sender, _pandaToken.balanceOf(msg.sender), _amountTokenMax);
        }

        uint256 _price = _currentPrice();
        uint256 tranTokens;
        
        
        uint256 _iTokenId;
        for (uint256 i = 0; i < _length; i++) {
            _iTokenId = _supplyTokens[i];
            _pandaNFT.safeTransferFrom(msg.sender, address(this), _iTokenId, "");
            tranTokens += _price;
            _poolPushNft(_iTokenId);
        }
        if (_amountTokenMax < tranTokens) {
            revert MaxBuyNotMatch(_amountTokenMax, tranTokens);
        }
        _pandaToken.safeTransferFrom(msg.sender, address(this), tranTokens);

        if (_pandaNFT.balanceOf(address(this)) < _updateMinPoolNftCount) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _updateMinPoolNftCount);
        }

        if(minPoolNFTCount != _updateMinPoolNftCount) {
            minPoolNFTCount = _updateMinPoolNftCount;
        }
        emit AddLiquidity(msg.sender, _supplyTokens, tranTokens, _updateMinPoolNftCount);
    }

    /**
     * @dev owner removeLiquidity.
     * @param _targetTokens remove these NFTs from pool
     * @param _amountTokenMin  Less than this value owner will not remove liquidity
     * @param _updateMinPoolNftCount update pool min nfts 
     */
    function removeLiquidity(uint256[] calldata _targetTokens, uint256[] calldata _targetPoolIndexs, uint256 _amountTokenMin, uint256 _updateMinPoolNftCount) external override onlyOwner nonReentrant {
        uint256 _length = _targetTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.balanceOf(address(this)) < _length) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _length);
        }

        IERC20 _pandaToken = IERC20(pandaToken);
        if (_pandaToken.balanceOf(address(this)) < _amountTokenMin) {
            revert PandaNotEnough(address(this), _pandaToken.balanceOf(address(this)), _amountTokenMin);
        }

        uint256 _price = _currentPrice();
        uint256 tranTokens;
        uint256 _iTargetTokenId;
        uint256 _iPoolIndex;
        for (uint256 i = 0; i < _length; i++) {
            _iTargetTokenId = _targetTokens[i];
            _iPoolIndex = _targetPoolIndexs[i];
            _pandaNFT.safeTransferFrom(address(this), msg.sender, _iTargetTokenId, "");
            {
                if(_getIdByIndex(_iPoolIndex) != _iTargetTokenId) {
                    revert PoolIndexNotMatchNFTId(_iPoolIndex, _getIdByIndex(_iPoolIndex), _iTargetTokenId);
                }
                _poolRemoveNft(_iPoolIndex);
            }
            
            tranTokens += _price;
        }

        if (_amountTokenMin > tranTokens) {
            revert MinReceiveNotMatch(_amountTokenMin, tranTokens);
        }
        _pandaToken.safeTransfer(msg.sender, tranTokens);

        if(_pandaNFT.balanceOf(address(this)) < _updateMinPoolNftCount) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _updateMinPoolNftCount);
        }
        if(minPoolNFTCount != _updateMinPoolNftCount) {
            minPoolNFTCount = _updateMinPoolNftCount;
        }

        emit RemoveLiquidity(msg.sender, _targetTokens, tranTokens, _updateMinPoolNftCount);
    }


    /**
     * @dev owner removePoolForUpdate.
     * @param _targetTokens remove these NFTs from pool
     */
    function removePoolForUpdate(uint256[] calldata _targetTokens, uint256[] calldata _targetPoolIndexs) external  onlyOwner nonReentrant {
        uint256 _length = _targetTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.balanceOf(address(this)) < _length) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _length);
        }

        uint256 _iTargetTokenId;
        uint256 _iPoolIndex;
        for (uint256 i = 0; i < _length; i++) {
            _iTargetTokenId = _targetTokens[i];
            _iPoolIndex = _targetPoolIndexs[i];
            _pandaNFT.safeTransferFrom(address(this), msg.sender, _iTargetTokenId, "");
            {
                if(_getIdByIndex(_iPoolIndex) != _iTargetTokenId) {
                    revert PoolIndexNotMatchNFTId(_iPoolIndex, _getIdByIndex(_iPoolIndex), _iTargetTokenId);
                }
                _poolRemoveNft(_iPoolIndex);
            }
        }

        emit RemovePoolForUpdate(msg.sender, _targetTokens);
    }


    /**
     * @dev owner addPoolforSwap.
     * @param _supplyTokens add these NFTs to pool
     */
    function addPoolForSwap(uint256[] calldata _supplyTokens) external  onlyOwner nonReentrant {

        uint256 _length = _supplyTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if(_pandaNFT.balanceOf(msg.sender) < _length) {
            revert UserNotEnoughNFT(msg.sender, _pandaNFT.balanceOf(msg.sender), _length);
        }
      
        uint256 _iTokenId;
        for (uint256 i = 0; i < _length; i++) {
            _iTokenId = _supplyTokens[i];
            _pandaNFT.safeTransferFrom(msg.sender, address(this), _iTokenId, "");
            _poolPushNft(_iTokenId);
        }
       
        emit AddPoolForSwap(msg.sender, _supplyTokens);
    }

//########################### Liquid Functions End ####################



//########################### CR Buy&Reborn Functions Start ####################

    function addCompensate(address user) external onlyOwner {
        buyCompensates[user] = true;
    }
    function removeCompensate(address user) external onlyOwner {
        buyCompensates[user] = false;
    }

    function addRebornCompensate(address user) external onlyOwner {
        rebornCompensates[user] = true;
    }
    function removeRebornCompensate(address user) external onlyOwner {
        rebornCompensates[user] = false;
    }

    function ownerCBuy(bytes32 _dataHash) external  nonReentrant  {
        if (!buyCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        buyCommits[msg.sender].commit = _dataHash;
        buyCommits[msg.sender].block = uint64(block.number);
        buyCommits[msg.sender].revealed = false;
        emit CommitOwnerBuy(msg.sender, buyCommits[msg.sender].commit, buyCommits[msg.sender].block);
    }

    function ownerRBuy(bytes32 revealHash) external  nonReentrant crOpen {
        if (!buyCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        buyCompensates[msg.sender] = false;
        if (buyCommits[msg.sender].revealed) {
            revert AlreadyRevealedError(msg.sender);
        }
        buyCommits[msg.sender].revealed=true;
        if (getHash(revealHash) != buyCommits[msg.sender].commit) {
            revert RevealedNotMatchError(getHash(revealHash), buyCommits[msg.sender].commit);
        }

        if (block.number <= buyCommits[msg.sender].block) {
            revert RevealHappenEarly(uint64(block.number), buyCommits[msg.sender].block);
        }
        
        if (block.number > buyCommits[msg.sender].block+250) {
            revert RevealTooLate(block.number, buyCommits[msg.sender].block+250);
        }
        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(buyCommits[msg.sender].block);
        //hash that with their reveal that so miner shouldn't know and mod it with some max number you want
        uint256 index = uint256(keccak256(abi.encodePacked(blockHash,revealHash))) % poolSize;
        uint256 targetIndex = _getIdByIndex(index);
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetIndex) != address(this)) {
            revert NFTOwnerNotMatch(targetIndex,  address(this), _pandaNFT.ownerOf(targetIndex));
        }

        if(_pandaNFT.balanceOf(address(this)) <= minPoolNFTCount) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), minPoolNFTCount);
        }
        _pandaNFT.safeTransferFrom(address(this), msg.sender, targetIndex, "");
        _poolRemoveNft(index);
        emit OwnerBuyRevealHash(msg.sender, revealHash, index, targetIndex);
    }

    function ownerCReborn(uint256 _ownerTokenId, bytes32 _dataHash) external nonReentrant crOpen {
        if (!rebornCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        rebornCommits[msg.sender].commit = _dataHash;
        rebornCommits[msg.sender].block = uint64(block.number);
        rebornCommits[msg.sender].revealed = false;
        rebornCommits[msg.sender].ownerTokenId = _ownerTokenId;
        emit CommitOwnerRebron(msg.sender, buyCommits[msg.sender].commit, buyCommits[msg.sender].block, _ownerTokenId);
    }


    function ownerRReborn(bytes32 revealHash) external  nonReentrant crOpen {
        if (!rebornCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        rebornCompensates[msg.sender] = false;
        if (rebornCommits[msg.sender].revealed) {
            revert AlreadyRevealedError(msg.sender);
        }
        rebornCommits[msg.sender].revealed=true;

        if (getHash(revealHash) != rebornCommits[msg.sender].commit) {
            revert RevealedNotMatchError(getHash(revealHash), rebornCommits[msg.sender].commit);
        }

        if (block.number <= rebornCommits[msg.sender].block) {
            revert RevealHappenEarly(block.number, buyCommits[msg.sender].block);
        }
        
        if (block.number > rebornCommits[msg.sender].block+250) {
            revert RevealTooLate(block.number, buyCommits[msg.sender].block+250);
        }

        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(rebornCommits[msg.sender].block);
        //hash that with their reveal that so miner shouldn't know and mod it with some max number you want
        uint256 index = uint256(keccak256(abi.encodePacked(blockHash,revealHash))) % poolSize;

        uint256 targetIndex = _getIdByIndex(index);
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetIndex) != address(this)) {
            revert NFTOwnerNotMatch(targetIndex, address(this), _pandaNFT.ownerOf(targetIndex));
        }
        
        _pandaNFT.safeTransferFrom(msg.sender, address(this), rebornCommits[msg.sender].ownerTokenId, "");
        _pandaNFT.safeTransferFrom(address(this), msg.sender, targetIndex, "");
        _poolPushNft(rebornCommits[msg.sender].ownerTokenId);
        _poolRemoveNft(index);
        emit OwnerRebornRevealHash(msg.sender, revealHash, rebornCommits[msg.sender].ownerTokenId, index, targetIndex);
    } 

    function getHash(bytes32 data) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), data));
    }           

//########################### CR Buy&Reborn Functions End ####################

//########################### Pool Utils Functions Start ####################

    function _safeTransferPanda(
        address to,
        uint256 value
    ) external override onlyAdmin {
        IERC20 _pandaToken = IERC20(pandaToken);
        _pandaToken.safeTransfer(to, value);
    }

    function _safeTransferFromPanda(
        address from,
        address to,
        uint256 value
    ) external override onlyAdmin {
        IERC20 _pandaToken = IERC20(pandaToken);
        _pandaToken.safeTransferFrom(from, to, value);
    }

    function _safeTransferToPanda(
        address to,
        uint256 value
    ) external override onlyAdmin {
        IERC20 _pandaToken = IERC20(pandaToken);
        _pandaToken.safeTransfer(to,  value);
    }

    function _safeTransferFromNFT(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyAdmin {
        IERC721 _pandaNFT = IERC721(pandaNFT);
        _pandaNFT.safeTransferFrom(from, to, tokenId, data);
    }

    function _poolSize() public override view returns(uint256) {
        return poolSize;
    }

    function _minPoolNFTCount() public override view returns(uint256) {
        return minPoolNFTCount;
    }

    function _poolRemoveNft(uint256 _index) public override onlyAdmin {
        if (_index >= poolSize) {
            revert PoolArrayIndexOutOfRange(_index, poolSize);
        }
        if (_index == poolSize - 1) {
            poolNftMap[_index] = 0;
        } else {
            poolNftMap[_index] = _getIdByIndex(poolSize - 1);//poolNftMap[poolSize - 1];
            poolNftMap[poolSize - 1] = 0;
        }
        poolSize--;
    }

    function _poolPushNft(uint256 _value) public override onlyAdmin {
        poolNftMap[poolSize] = _value;
        poolSize++;
    }

    function _getIdByIndex(uint256 _index) public override returns(uint256) {
        if (_index >= poolSize) {
            revert PoolArrayIndexOutOfRange(_index, poolSize);
        }
        if(poolNftMap[_index] == 0) {
            poolNftMap[_index] = _index + poolIndexBase;
            return poolNftMap[_index];
        } else {
            return poolNftMap[_index];
        }
    }

    /**
     * @dev calculate current price
     */
    function _currentPrice() public view override returns(uint256 _price) {
        if (IERC721(pandaNFT).balanceOf(address(this)) < NFT_TOTAL_SUPPLY) {
            _price = IERC20(pandaToken).balanceOf(address(this)) / (NFT_TOTAL_SUPPLY - poolSize);
        } else {
            _price = IERC20(pandaToken).balanceOf(address(this));
        }
        
    }   


    function _resetPandaPool(uint256 _size, uint256 _poolIndexBase) external onlyOwner {
        poolSize = _size;
        poolIndexBase = _poolIndexBase;
        emit ResetPandaPool(_size, _poolIndexBase);
    } 

    function _updatePandaPoolMin(uint256 _updateMinPoolNftCount) external onlyOwner {
        minPoolNFTCount = _updateMinPoolNftCount;
        emit UpdatePandaPool(_updateMinPoolNftCount);
    } 

//########################### Pool Utils Functions End ####################

    /**
     * @dev setLiquidityClose close or open swap、redeem、buy.
     * @param _poolOpne true or false
     * @param _crOpen true or false          
     */
    function setSwitchs(bool _poolOpne, bool _crOpen) external onlyOwner {
        isPoolOpen = _poolOpne;
        isCrOpen = _crOpen;
        emit SwitchEvent(_poolOpne, _crOpen);
    }

    function setPoolFeeValue(uint256 _feeValue) external onlyOwner {
        poolFeeValue = _feeValue;
        emit SetPoolFeeValue(_feeValue);
    }

    function setTreasuryFeeValue(uint256 _feeValue) external onlyOwner {
        treasuryFeeValue = _feeValue;
        emit SetTreasuryFeeValue(_feeValue);
    }


    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data ) pure external override returns (bytes4) {
        return this.onERC721Received.selector;
    } 

    /**
     * @dev withdrawERC20  tokens.
     * @param _recipient recipient
     * @param _tokenAddress  token
     * @param _tokenAmount amount
     */
    function withdrawERC20(address _recipient, address _tokenAddress, uint256 _tokenAmount) external onlyOwner notZeroAddr(_tokenAddress) {
        IERC20(_tokenAddress).safeTransfer(_recipient, _tokenAmount);
        emit WithdrawERC20(_recipient, _tokenAddress, _tokenAmount);
    }
    

    /**
     * @dev withdraw Ether.
     * @param recipient recipient
     * @param amount amount
     */
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        (bool success,) = recipient.call{value:amount}("");
        if(!success) {
            revert TransferEhterFail(msg.sender, recipient, amount);
        }
        emit WithdrawEther(recipient, amount);
    }


    fallback () external payable {}

    receive () external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IPandaPool {
    
    function redeem(uint256 _ownerTokenId, uint256 _amountRedeemMin, uint256 _deadline) external;

    function addLiquidity(uint256[] calldata _supplyTokens, uint256 _amountTokenMax, uint256 _updateMinPoolNftCount, uint256 _deadline) external;

    function removeLiquidity(uint256[] calldata _targetTokens, uint256[] calldata _targetPoolIndexs, uint256 _amountTokenMin, uint256 _updateMinPoolNftCount) external;
    
}

/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IPoolKit {
    function _safeTransferPanda(address to, uint256 value) external;
    
    function _safeTransferFromPanda(address from, address to, uint256 value) external;

    function _safeTransferFromNFT(address from, address to, uint256 tokenId, bytes calldata data) external;

    function _poolSize() external view returns(uint256);

    function _poolRemoveNft(uint256 _index) external;

    function _poolPushNft(uint256 _value) external ;

    function _getIdByIndex(uint256 _index) external returns(uint256);

    function _currentPrice() external view returns(uint256 _price);

    function _minPoolNFTCount() external view returns(uint256);

    function _safeTransferToPanda(address to,uint256 value) external ;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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