/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

contract PrivateSale is Ownable, ReentrancyGuard {

    uint256 public tokenPrice = 15;

    uint256 public startTime = 1645212946;

    uint256 public period = 14;
    
    mapping(uint8 => uint256) public slotPrice;
    
    mapping(uint8 => uint256) public availableSlotAmount;

    mapping(address => uint256) public balanceOfST3;
    
    mapping(address => uint8) public bonus;
    
    address public fundTarget = 0xe921BAeca17C41D8266B84F1709Cb947595F65A8;

    address public stabl3;

    event TokenBought(address buyer, uint256 amount);

    constructor(address _stabl3) {
        slotPrice[1] = 1000000;
        slotPrice[2] = 100000;
        slotPrice[3] = 50000;
        slotPrice[4] = 10000;
        slotPrice[5] = 5000;
        slotPrice[6] = 2500;
        slotPrice[7] = 1000;

        availableSlotAmount[1] = 1;
        availableSlotAmount[2] = 3;
        availableSlotAmount[3] = 5;
        availableSlotAmount[4] = 20;
        availableSlotAmount[5] = 100;
        availableSlotAmount[6] = 100;
        availableSlotAmount[7] = 200;

        stabl3 = _stabl3;
    }

    function setTime(uint256 _startTime, uint256 _period) public onlyOwner {
        startTime = _startTime;
        period = _period;
    }

    function setTokenPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    function setFundTarget(address _fundTarget) public onlyOwner {
      fundTarget = _fundTarget;
    }

    // get balanceOfST3 mapping value by key
    function checkStabl3(address addr) public view returns(uint256) {
        return balanceOfST3[addr];
    }

    // get slotPrice mapping value by key
    function getSlotPriceValue(uint8 slotIndex) public view returns(uint256) {
        return slotPrice[slotIndex];
    }
    function getSlotPriceValues() public view returns (uint[] memory) {
        uint256[] memory memoryArray = new uint256[](8);
        for(uint8 i = 1; i <= 7; i++){
            memoryArray[i] = slotPrice[i];
        }
        return memoryArray;
    }

    // get availableSlotAmount mapping value by key
    function getAvailableSlotAmountValue(uint8 slotIndex) public view returns(uint256) {
        return availableSlotAmount[slotIndex];
    }
    function getAvailableSlotAmountValues() public view returns (uint[] memory) {
        uint[] memory memoryArray = new uint[](8);
        for(uint8 i = 1; i <= 7; i++) {
            memoryArray[i] = availableSlotAmount[i];
        }
        return memoryArray;
    }
    
    // get bonus mapping value by key
    function getBonusValue(address addr) public view returns(uint8) {
        return bonus[addr];
    }

    modifier afterClosed() {
        require(block.timestamp > startTime + period * 24 * 3600, "Private sale is open now.");
        _;
    }

    function buy(address token, uint8 slotIndex) public nonReentrant {
        require(block.timestamp >= startTime, "Private Sale is not started.");
        require(block.timestamp <= startTime + period * 24 * 3600, "Private Sale is closed.");
        require(availableSlotAmount[slotIndex] > 0, "SOLD OUT");
        
        uint256 decimals = IERC20(token).decimals();
        uint256 tokenAmount = slotPrice[slotIndex] * 10 ** decimals;
        IERC20(token).transferFrom(msg.sender, address(fundTarget), tokenAmount);

        uint256 stabl3Amount = tokenAmount * 1000 / tokenPrice;
        uint256 maxAmount = IERC20(stabl3).balanceOf(address(this));
        require(stabl3Amount <= maxAmount, "Available token amount is not enough.");

        IERC20(stabl3).transfer(msg.sender, stabl3Amount);

        balanceOfST3[msg.sender] = balanceOfST3[msg.sender] + stabl3Amount;
        availableSlotAmount[slotIndex] = availableSlotAmount[slotIndex] - 1;
        // availableAmount
        //123

        if (slotIndex < 5 && bonus[msg.sender] < slotIndex) {
            bonus[msg.sender] = slotIndex;
        }

        emit TokenBought(msg.sender, stabl3Amount);
    }
}