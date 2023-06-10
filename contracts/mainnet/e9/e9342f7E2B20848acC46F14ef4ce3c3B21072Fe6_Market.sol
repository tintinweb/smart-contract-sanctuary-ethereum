// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract Market is Ownable {
    struct OfferDetails {
        uint256 _id;
        address _tokenA;
        uint256 _amountA;
        address _tokenB;
        uint256 _amountB;
        uint256 _endTime;
        address _Creator;
        uint256 _active; // active: 0, claim: 1, cancel: 2
        bool    _type; // 0: buy, 1: sell
        bool    _public; // 0: private, 1: public
    }

    bool public whiteListRequired = false;
    uint256 public totalOffers;

    address private burnAddress = 0x0000000000000000000000000000000000000001;

    address public pearTokenContract = 0x5dCD6272C3cbb250823F0b7e6C618bce11B21f90; // PEAR token contract address(ETH Mainnet)
    uint256 public pearBurnCount = 50 * 1000000000000000000;

    mapping(address => bool) public whiteListedToken;

    mapping(uint256 => OfferDetails) public OfferId;
    mapping(uint256 => bool) public OfferCompleted;

    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public tokenExist;

    mapping(address => uint256) public rewardBalance;
    mapping(address => uint256) public platformBalance;

    mapping(uint256 => address) public tokenAddress;
    uint256 public totalTokens;

    event OfferCreated(
        address creator,
        uint256 userOfferId,
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB,
        bool    _type,
        bool    _public
    );

    event OfferClosed(uint256 offerId);

    constructor() {
        whiteListedToken[address(0)] = true;
    }

    fallback() external payable {}

    receive() external payable {}

    /**
    * @notice
    transactionFee is 100 because it is used to represent 0.01, since we only use integer numbers
    This will give 1% fee for each transaction
    */
    uint256 internal transactionFee = 100;
    uint256 internal platformFee = 200;

    function whiteListToken(address _token) public onlyOwner {
        whiteListedToken[_token] = true;
    }

    function flipWhiteList() public onlyOwner {
        whiteListRequired = !whiteListRequired;
    }

    function makeOffer(
        address _token,
        uint256 _amount,
        address _tokenB,
        uint256 _amountB,
        uint256 _endTime,
        bool    _type,
        bool    _public
    ) public payable {
        if (whiteListRequired) {
            require(
                whiteListedToken[_token] == true,
                "Token not allowed for sales yet"
            );
        }

        // check pear token and transfer it from caller to this contract
        checkPear(msg.sender);
        IERC20(pearTokenContract).transferFrom(msg.sender, address(this), pearBurnCount);

        if (_token == address(0)) {
            require(msg.value == _amount, "You must send ETH equal to amount");
            require(isContract(_tokenB), "Received token must be a contract");
        }

        if (_token != address(0)) {
            require(
                isContract(_token),
                "Your offered token must be a contract"
            );
            checkOffer(msg.sender, _token, _amount);
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }

        OfferId[totalOffers]._id = totalOffers;
        OfferId[totalOffers]._tokenA = _token;
        OfferId[totalOffers]._amountA = _amount;
        OfferId[totalOffers]._tokenB = _tokenB;
        OfferId[totalOffers]._amountB = _amountB;
        OfferId[totalOffers]._endTime = _endTime;
        OfferId[totalOffers]._Creator = msg.sender;
        OfferId[totalOffers]._active = 0;
        OfferId[totalOffers]._type = _type;
        OfferId[totalOffers]._public = _public;

        emit OfferCreated(
            msg.sender,
            totalOffers,
            _token,
            _amount,
            _tokenB,
            _amountB,
            _type,
            _public
        );

        totalOffers += 1;
    }

    function acceptOffer(uint256 _id) public payable {
        require(OfferCompleted[_id] == false, "Offer already closed");
        require(block.timestamp <= OfferId[_id]._endTime, "The time is up.");
        
        address tokenA = OfferId[_id]._tokenA;
        address tokenB = OfferId[_id]._tokenB;
        uint256 amountA = OfferId[_id]._amountA;
        uint256 amountB = OfferId[_id]._amountB;
        address creator = OfferId[_id]._Creator;

        uint256 feeA = amountA / transactionFee;
        uint256 rawAmountA = amountA - feeA;
        uint256 feeB = amountB / transactionFee;
        uint256 rawAmountB = amountB - feeB;

        uint256 platformFeeA = amountA / platformFee;
        uint256 platformFeeB = amountB / platformFee;

        if(tokenA == address(0)) {
            payable(msg.sender).transfer(rawAmountA);
        } else {
            IERC20(tokenA).transfer(msg.sender, rawAmountA);
        }

        if (tokenB == address(0)) {
            require(
                msg.value == amountB,
                "Not enough ETH to proceed this offer"
            );

            payable(creator).transfer(rawAmountB);
        } else {
            checkOffer(msg.sender, tokenB, amountB);

            IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
            IERC20(tokenB).transfer(creator, rawAmountB);
        }

        if(!tokenExist[tokenA]) {
            tokenExist[tokenA] = true;
            tokenBalance[tokenA] = feeA;

            rewardBalance[tokenA] = feeA - platformFeeA;
            platformBalance[tokenA] = platformFeeA;

            tokenAddress[totalTokens] = tokenA;
            totalTokens += 1;
        } else {
            tokenBalance[tokenA] += feeA;

            rewardBalance[tokenA] += feeA - platformFeeA;
            platformBalance[tokenA] += platformFeeA;
        }

        if(!tokenExist[tokenB]) {
            tokenExist[tokenB] = true;
            tokenBalance[tokenB] = feeB;

            rewardBalance[tokenB] = feeB - platformFeeB;
            platformBalance[tokenB] = platformFeeB;

            tokenAddress[totalTokens] = tokenB;
            totalTokens += 1;
        } else {
            tokenBalance[tokenB] += feeB;

            rewardBalance[tokenB] += feeB - platformFeeB;
            platformBalance[tokenB] += platformFeeB;
        }

        // Burn PEAR token on this contract
        uint256 pearBalance = IERC20(pearTokenContract).balanceOf(address(this));        
        require(pearBalance >= pearBurnCount, "Contract internal issue, don't have enough PEAR balance");
        IERC20(pearTokenContract).transfer(burnAddress, pearBurnCount);

        OfferCompleted[_id] = true;

        emit OfferClosed(_id);

        OfferId[_id]._active = 1;
    }

    function cancelOffer(uint256 _id) public payable {
        require(OfferCompleted[_id] == false, "Offer already closed");

        address tokenA = OfferId[_id]._tokenA;
        uint256 amountA = OfferId[_id]._amountA;
        address creator = OfferId[_id]._Creator;

        require(msg.sender == creator, "You are not the owner of this offer");

        // return PEAR token from this contract
        uint256 pearBalance = IERC20(pearTokenContract).balanceOf(address(this));        
        require(pearBalance >= pearBurnCount, "Contract internal issue, don't have enough PEAR balance");
        IERC20(pearTokenContract).transfer(creator, pearBurnCount);

        OfferCompleted[_id] = true;
        OfferId[_id]._active = 2;
        emit OfferClosed(_id);

        if (tokenA == address(0)) {
            payable(creator).transfer(amountA);
        }
        if (tokenA != address(0)) {
            IERC20(tokenA).transfer(creator, amountA);
        }
    }

    function checkPear(address Offerer) internal view {
        uint256 pearApproved = IERC20(pearTokenContract).allowance(Offerer, address(this));

        require(
            pearApproved >= pearBurnCount,
            "Insufficient allowance, Approve PEAR first"
        );

        uint256 pearBalance = IERC20(pearTokenContract).balanceOf(Offerer);
        
        require(pearBalance >= pearBurnCount, "You don't have enough PEAR balance");
    }

    function checkOffer(
        address Offerer,
        address _token,
        uint256 _amount
    ) internal view {
        uint256 approved = IERC20(_token).allowance(Offerer, address(this));

        require(
            approved >= _amount,
            "Insufficient allowance, Approve token first"
        );

        uint256 userBalance = IERC20(_token).balanceOf(Offerer);

        require(userBalance >= _amount, "You don't have enough balance");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function getCounts() external view returns (uint256) {
        return totalOffers;
    }

    function getOfferDetail(
        uint256 id
    ) external view returns (OfferDetails memory) {
        return OfferId[id];
    }

    function getUserOffers(
        address user
    ) external view returns (OfferDetails[] memory) {
        uint256 count = 0;
        uint256 i = 0;
        for (i = 0; i < totalOffers; i++) {
            if (OfferId[i]._Creator == user) {
                count++;
            }
        }

        OfferDetails[] memory result = new OfferDetails[](count);
        uint256 index = 0;
        for (i = 0; i < totalOffers; i++) {
            if (OfferId[i]._Creator == user) {
                result[index] = OfferId[i];
                index++;
            }
        }
        return result;
    }

    function isWhitelistedToken(address token) external view returns (bool) {
        return whiteListedToken[token];
    }

    function isOfferCompleted(uint256 id) external view returns (bool) {
        return OfferCompleted[id];
    }

    function transfer(address _token, address _to, uint256 _amount, bool _reward) public onlyOwner {
        require(_to != address(0x0) && _to != address(this), "destination address is not valid");

        uint256 _tokenBalance = IERC20(_token).balanceOf(address(this));
        
        require(_tokenBalance >= _amount, "no enough amount to transfer");

        if (_reward) {
            require(rewardBalance[_token] >= _amount, "no enough amount to transfer in reward pool");
        } else {
            require(platformBalance[_token] >= _amount, "no enough amount to transfer in platform pool");
        }

        require(IERC20(_token).transfer(_to, _amount), "transfer failed");
    }
}