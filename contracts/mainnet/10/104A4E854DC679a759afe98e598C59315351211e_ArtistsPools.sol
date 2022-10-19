// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract PoolTokenWrapper {
    using SafeMath for uint256;
    IERC20 public token;

    constructor(IERC20 _erc20Address) {
        token = IERC20(_erc20Address);
    }

    uint256 private _totalSupply;
    // Objects balances [id][address] => balance
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => uint256) private _accountBalances;
    mapping(uint256 => uint256) private _poolBalances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOfAccount(address account) public view returns (uint256) {
        return _accountBalances[account];
    }

    function balanceOfPool(uint256 id) public view returns (uint256) {
        return _poolBalances[id];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _balances[id][account];
    }

    function stake(uint256 id, uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _poolBalances[id] = _poolBalances[id].add(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].add(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].add(amount);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 id, uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _poolBalances[id] = _poolBalances[id].sub(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
        token.transfer(msg.sender, amount);
    }

    function transfer(
        uint256 fromId,
        uint256 toId,
        uint256 amount
    ) public virtual {
        _poolBalances[fromId] = _poolBalances[fromId].sub(amount);
        _balances[fromId][msg.sender] = _balances[fromId][msg.sender].sub(
            amount
        );

        _poolBalances[toId] = _poolBalances[toId].add(amount);
        _balances[toId][msg.sender] = _balances[toId][msg.sender].add(amount);
    }

    function _rescuePineapples(address account, uint256 id) internal {
        uint256 amount = _balances[id][account];

        _totalSupply = _totalSupply.sub(amount);
        _poolBalances[id] = _poolBalances[id].sub(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
        _balances[id][account] = _balances[id][account].sub(amount);
        token.transfer(account, amount);
    }
}

interface MEME721 {
    function totalSupply(uint256 _id) external view returns (uint256);

    function maxSupply(uint256 _id) external view returns (uint256);

    function mint(address _to, uint256 _baseTokenID) external returns (uint256);

    function create(uint256 _maxSupply) external returns (uint256 tokenId);
}

interface Auction {
    function create(
        uint256 poolID,
        address artistAddress,
        uint256 start,
        uint256 duration,
        uint256 extension, // in minutes
        address nftAddress,
        bool isArtistContract,
        bool isERC721,
        uint256 nftTokenID,
        address nftHolder,
        bool isFunBid
    ) external returns (uint256 id);
}

contract ArtistsPools is
    PoolTokenWrapper,
    Ownable,
    IERC1155Receiver,
    IERC721Receiver
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct CardNFT {
        uint256 supply;
        uint256 minted;
        bool isERC721;
        bool isMEME721;
        address nftAddress;
        uint256[] tokenID;
    }

    struct Card {
        uint256 points;
        uint256 releaseTime;
        uint256 mintFee;
        bool isETHFee;
        CardNFT cardNFT;
    }

    struct Pool {
        address owner;
        uint256 periodStart;
        uint256 maxStake;
        uint256 spentPineapples;
        uint256 controllerShare;
        address artist;
        mapping(address => uint256) lastUpdateTime;
        mapping(address => uint256) points;
        mapping(uint256 => Card) cards;
        uint256[] auctions;
    }

    address public controller;
    uint256 public controllerShare;
    address public rescuer;
    bool public open;
    mapping(address => uint256) public pendingWithdrawalsETH;
    mapping(address => uint256) public pendingWithdrawalsMEME;
    mapping(uint256 => Pool) public pools;
    Counters.Counter poolsID;
    mapping(uint256 => Counters.Counter) cardIDs;

    IERC20 public memeToken;
    Auction public auction;
    MEME721 public meme721;

    event UpdatedArtist(uint256 poolId, address artist);
    event PoolAdded(
        uint256 poolId,
        address artist,
        uint256 periodStart,
        uint256 maxStake
    );
    event CardAdded(
        uint256 poolId,
        uint256 cardId,
        uint256 points,
        uint256 mintFee,
        uint256 releaseTime
    );
    event Staked(address indexed user, uint256 poolId, uint256 amount);
    event Withdrawn(address indexed user, uint256 poolId, uint256 amount);
    event Transferred(
        address indexed user,
        uint256 fromPoolId,
        uint256 toPoolId,
        uint256 amount
    );
    event Redeemed(address indexed user, uint256 poolId, uint256 amount);

    modifier updateReward(address account, uint256 id) {
        if (account != address(0)) {
            pools[id].points[account] = earned(account, id);
            pools[id].lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    modifier poolExists(uint256 id) {
        require(pools[id].owner != address(0), "pool does not exists");
        _;
    }

    modifier cardExists(uint256 pool, uint256 card) {
        require(pools[pool].cards[card].points > 0, "card does not exists");
        _;
    }

    modifier ownerOrPoolOwner(uint256 pool) {
        require(
            owner() == msg.sender || (open && pools[pool].owner == msg.sender),
            "not open to public or you are not the owner of the pool"
        );
        _;
    }

    constructor(
        address _controller,
        address _memeNFTAddress,
        IERC20 _tokenAddress,
        address _auctionAddress
    ) PoolTokenWrapper(_tokenAddress) {
        controller = _controller;
        meme721 = MEME721(_memeNFTAddress);
        memeToken = IERC20(address(_tokenAddress));
        auction = Auction(_auctionAddress);
    }

    function cardBaseInfo(uint256 pool, uint256 card)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            pools[pool].cards[card].points,
            pools[pool].cards[card].releaseTime,
            pools[pool].cards[card].mintFee,
            pools[pool].cards[card].isETHFee
        );
    }

    function cardNFTInfo(uint256 pool, uint256 card)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            bool,
            address,
            uint256[] memory
        )
    {
        return (
            pools[pool].cards[card].cardNFT.supply,
            pools[pool].cards[card].cardNFT.minted,
            pools[pool].cards[card].cardNFT.isERC721,
            pools[pool].cards[card].cardNFT.isMEME721,
            pools[pool].cards[card].cardNFT.nftAddress,
            pools[pool].cards[card].cardNFT.tokenID
        );
    }

    function earned(address account, uint256 pool)
        public
        view
        returns (uint256)
    {
        Pool storage p = pools[pool];
        uint256 blockTime = block.timestamp;
        return
            p.points[account].add(
                blockTime
                    .sub(
                        p.lastUpdateTime[account] >= p.periodStart
                            ? p.lastUpdateTime[account]
                            : p.periodStart
                    )
                    .mul(balanceOf(account, pool))
                    .div(86400)
            );
    }

    // override PoolTokenWrapper's stake() function
    function stake(uint256 pool, uint256 amount)
        public
        override
        poolExists(pool)
        updateReward(msg.sender, pool)
    {
        Pool storage p = pools[pool];

        require(block.timestamp >= p.periodStart, "pool not open");
        require(
            amount.add(balanceOf(msg.sender, pool)) <= p.maxStake,
            "stake exceeds max"
        );

        super.stake(pool, amount);
        emit Staked(msg.sender, pool, amount);
    }

    // override PoolTokenWrapper's withdraw() function
    function withdraw(uint256 pool, uint256 amount)
        public
        override
        poolExists(pool)
        updateReward(msg.sender, pool)
    {
        require(amount > 0, "cannot withdraw 0");

        super.withdraw(pool, amount);
        emit Withdrawn(msg.sender, pool, amount);
    }

    // override PoolTokenWrapper's transfer() function
    function transfer(
        uint256 fromPool,
        uint256 toPool,
        uint256 amount
    )
        public
        override
        poolExists(fromPool)
        poolExists(toPool)
        updateReward(msg.sender, fromPool)
        updateReward(msg.sender, toPool)
    {
        Pool storage toP = pools[toPool];

        require(block.timestamp >= toP.periodStart, "pool not open");
        require(
            amount.add(balanceOf(msg.sender, toPool)) <= toP.maxStake,
            "stake exceeds max"
        );

        super.transfer(fromPool, toPool, amount);
        emit Transferred(msg.sender, fromPool, toPool, amount);
    }

    function transferAll(uint256 fromPool, uint256 toPool) external {
        transfer(fromPool, toPool, balanceOf(msg.sender, fromPool));
    }

    function exit(uint256 pool) external {
        withdraw(pool, balanceOf(msg.sender, pool));
    }

    function redeem(uint256 pool, uint256 card)
        public
        payable
        poolExists(pool)
        cardExists(pool, card)
        updateReward(msg.sender, pool)
    {
        Pool storage p = pools[pool];
        Card memory c = p.cards[card];
        require(block.timestamp >= c.releaseTime, "card not released");
        require(p.points[msg.sender] >= c.points, "not enough pineapples");
        require(c.cardNFT.supply < c.cardNFT.minted, "Max supply reached");
        if (c.isETHFee) {
            require(msg.value == c.mintFee, "support our artists, send eth");
        } else {
            require(
                memeToken.balanceOf(msg.sender) >= c.mintFee,
                "support our artists, send meme"
            );
        }

        if (c.mintFee > 0) {
            uint256 _controllerShare = c.mintFee.mul(p.controllerShare).div(
                1000
            );
            uint256 _artistRoyalty = c.mintFee.sub(_controllerShare);
            require(
                _artistRoyalty.add(_controllerShare) == c.mintFee,
                "problem with fee"
            );

            if (c.isETHFee) {
                pendingWithdrawalsETH[controller] = pendingWithdrawalsETH[
                    controller
                ].add(_controllerShare);
                pendingWithdrawalsETH[p.artist] = pendingWithdrawalsETH[
                    p.artist
                ].add(_artistRoyalty);
            } else {
                memeToken.transferFrom(msg.sender, address(this), c.mintFee);

                pendingWithdrawalsMEME[controller] = pendingWithdrawalsMEME[
                    controller
                ].add(_controllerShare);
                pendingWithdrawalsMEME[p.artist] = pendingWithdrawalsMEME[
                    p.artist
                ].add(_artistRoyalty);
            }
        }

        p.points[msg.sender] = p.points[msg.sender].sub(c.points);
        p.spentPineapples = p.spentPineapples.add(c.points);

        // mint nfts

        c.cardNFT.minted = c.cardNFT.minted.add(1);

        if (c.cardNFT.isMEME721) {
            meme721.mint(msg.sender, c.cardNFT.tokenID[0]);
        } else if (c.cardNFT.isERC721) {
            for (uint256 i = 0; i < c.cardNFT.supply; ++i) {
                if (
                    IERC721(c.cardNFT.nftAddress).ownerOf(
                        c.cardNFT.tokenID[i]
                    ) == address(this)
                ) {
                    IERC721(c.cardNFT.nftAddress).safeTransferFrom(
                        address(this),
                        msg.sender,
                        c.cardNFT.tokenID[i]
                    );
                    break;
                }
            }
        } else {
            IERC1155(c.cardNFT.nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                c.cardNFT.tokenID[0],
                1,
                ""
            );
        }

        emit Redeemed(msg.sender, pool, c.points);
    }

    function rescuePineapples(address account, uint256 pool)
        public
        poolExists(pool)
        updateReward(account, pool)
        returns (uint256)
    {
        require(msg.sender == rescuer, "!rescuer");
        Pool storage p = pools[pool];

        uint256 earnedPoints = p.points[account];
        p.spentPineapples = p.spentPineapples.add(earnedPoints);
        p.points[account] = 0;

        // transfer remaining MEME to the account
        if (balanceOf(account, pool) > 0) {
            _rescuePineapples(account, pool);
        }

        emit Redeemed(account, pool, earnedPoints);
        return earnedPoints;
    }

    function setArtist(uint256 pool, address artist)
        public
        poolExists(pool)
        ownerOrPoolOwner(pool)
    {
        pools[pool].artist = artist;
        emit UpdatedArtist(pool, artist);
    }

    function setControllerShare(uint256 _controllerShare) public onlyOwner {
        controllerShare = _controllerShare;
    }

    function setRescuer(address _rescuer) public onlyOwner {
        rescuer = _rescuer;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setMeme721(address _address) public onlyOwner {
        meme721 = MEME721(_address);
    }

    function setMemeToken(address _address) public onlyOwner {
        memeToken = IERC20(address(_address));
    }

    function setAuction(address _address) public onlyOwner {
        auction = Auction(_address);
    }

    function setPoolReleaseTime(uint256 pool, uint256 time)
        public
        poolExists(pool)
        ownerOrPoolOwner(pool)
    {
        pools[pool].periodStart = time;
    }

    function createAuction(
        uint256 pool,
        address artistAddress,
        uint256 start,
        uint256 duration,
        uint256 extension, // in minutes
        address nftAddress,
        bool isArtistContract,
        bool isERC721,
        uint256 nftTokenID,
        bool isFunBid
    ) public poolExists(pool) ownerOrPoolOwner(pool) {
        uint256 auctionID = auction.create(
            pool,
            artistAddress,
            start,
            duration,
            extension,
            nftAddress,
            isArtistContract,
            isERC721,
            nftTokenID,
            msg.sender,
            isFunBid
        );
        pools[pool].auctions.push(auctionID);
    }

    function createCard(
        uint256 pool,
        uint256 supply,
        uint256 points,
        uint256 mintFee,
        bool isETHFee,
        uint256 releaseTime,
        bool isERC721,
        bool isMEME721,
        address nftAddress,
        uint256[] memory tokenID
    ) public poolExists(pool) {
        require(
            owner() == msg.sender || (open && pools[pool].owner == msg.sender),
            "not open to public or you are not the owner of the pool"
        );
        if (isMEME721) {
            uint256 mintID = meme721.create(supply);
            isERC721 = true;
            nftAddress = address(meme721);
            tokenID[0] = mintID;
        } else {
            // transfer NFTs to contract
            if (isERC721) {
                require(tokenID.length == supply, "invalid tokenID length");
                for (uint256 i = 0; i < supply; ++i)
                    IERC721(nftAddress).safeTransferFrom(
                        msg.sender,
                        address(this),
                        tokenID[i]
                    );
            } else {
                require(tokenID.length == 1, "invalid tokenID length");
                IERC1155(nftAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenID[0],
                    supply,
                    ""
                );
            }
        }

        uint256 id = cardIDs[pool].current();

        Card storage c = pools[pool].cards[id];
        c.points = points;
        c.releaseTime = releaseTime;
        c.mintFee = mintFee;
        c.isETHFee = isETHFee;
        c.cardNFT.supply = supply;
        c.cardNFT.minted = 0;
        c.cardNFT.isERC721 = isERC721;
        c.cardNFT.isMEME721 = isMEME721;
        c.cardNFT.nftAddress = nftAddress;
        c.cardNFT.tokenID = tokenID;

        cardIDs[pool].increment();
        emit CardAdded(pool, id, points, mintFee, releaseTime);
    }

    function addCard(
        uint256 pool,
        uint256 supply,
        uint256 points,
        uint256 mintFee,
        bool isETHFee,
        uint256 releaseTime,
        bool isERC721,
        address nftAddress,
        uint256[] memory tokenID
    ) public onlyOwner poolExists(pool) {
        uint256 id = cardIDs[pool].current();

        Card storage c = pools[pool].cards[id];
        c.points = points;
        c.releaseTime = releaseTime;
        c.mintFee = mintFee;
        c.isETHFee = isETHFee;
        c.cardNFT.supply = supply;
        c.cardNFT.minted = 0;
        c.cardNFT.isERC721 = isERC721;
        c.cardNFT.nftAddress = nftAddress;
        c.cardNFT.tokenID = tokenID;

        cardIDs[pool].increment();
        emit CardAdded(pool, id, points, mintFee, releaseTime);
    }

    function createPool(uint256 periodStart, address artist)
        public
        returns (uint256)
    {
        require(owner() == msg.sender || open, "not open to public");

        uint256 id = poolsID.current();
        Pool storage p = pools[id];
        p.owner = msg.sender;
        p.periodStart = periodStart;
        p.maxStake = 5 * 1e18;
        p.controllerShare = controllerShare;
        p.artist = artist;

        poolsID.increment();
        emit PoolAdded(id, artist, periodStart, p.maxStake);

        return id;
    }

    function withdrawETHFee() public {
        uint256 amount = pendingWithdrawalsETH[msg.sender];
        require(amount > 0, "nothing to withdraw");
        pendingWithdrawalsETH[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawMEMEFee() public {
        uint256 amount = pendingWithdrawalsMEME[msg.sender];
        require(amount > 0, "nothing to withdraw");
        pendingWithdrawalsMEME[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function rescue721NFT(
        address nftAddress,
        uint256 nftID,
        address toAddress
    ) external onlyOwner {
        IERC721(nftAddress).safeTransferFrom(address(this), toAddress, nftID);
    }

    function rescue1155NFT(
        address nftAddress,
        uint256 nftID,
        uint256 amount,
        address toAddress
    ) external onlyOwner {
        IERC1155(nftAddress).safeTransferFrom(
            address(this),
            toAddress,
            nftID,
            amount,
            ""
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC1155).interfaceId;
    }
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

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}