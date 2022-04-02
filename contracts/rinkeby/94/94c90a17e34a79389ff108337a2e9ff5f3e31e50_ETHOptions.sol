/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/interfaces/IUniOptV1ERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniOptV1ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function nonces(address owner) external view returns (uint);

}


// File contracts/libraries/SafeMath.sol


pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


// File contracts/UniOptV1ERC20.sol


pragma solidity ^0.8.0;
contract UniOptV1ERC20 is IUniOptV1ERC20 {
    using SafeMath for uint;

    string public override name ;
    string public override symbol;
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public  override allowance;

    mapping(address => uint) public override nonces;

    function _mint(address to, uint value) internal  {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal  {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private  {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private  {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) override external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File contracts/libraries/TransferHelper.sol


pragma solidity ^0.8.0;
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}


// File contracts/ETHOptions.sol


pragma solidity ^0.8.0;
contract ETHOptions is UniOptV1ERC20{
    using SafeMath for uint;
    address constant dai =0x2Ec4c6fCdBF5F9beECeB1b51848fc2DB1f3a26af;
    address public releaser;
    address public Factory; //TODO
    uint256 public deadline;
    uint256 public assetPrice;
    constructor(){
        Factory = msg.sender;
    }
    function initialize(address _caller, uint256 _deadline, uint256 _price) payable public{
        require(msg.sender == Factory);
        require(_deadline > block.timestamp,"DLS");//DEADLINE is too Small
        releaser = _caller;
        deadline = _deadline;
        assetPrice = _price;  //unit: dai/ether
        name = string(abi.encodePacked("ETH_PRICE", Strings.toString(_price),"usd", "_UNIX", Strings.toString(uint256(_deadline))) );
        symbol = string(abi.encodePacked("OPT", Strings.toString(_price)));
        _releaseOPT(uint(msg.value));
    }

    function _releaseOPT(uint amount)  internal{
        _mint(releaser, amount);  //1ETH = 10*10^18
    }
    
    function takeETH() public{
        require(block.timestamp > deadline);
        uint amount = this.balanceOf(address(msg.sender));
        _burn(msg.sender, amount);
        uint needPay = amount.mul(assetPrice);//needpay = x*10^18 * y dai
        TransferHelper.safeTransferFrom(dai, msg.sender, releaser, needPay);
        TransferHelper.safeTransferETH(msg.sender, amount);//unit: wei
        
    }

    function burnAll()  public{
        require(msg.sender == releaser,"only Releaser");
        require(block.timestamp >= deadline + 1 days,"not now");
        selfdestruct(payable(msg.sender));
    }


}


// File contracts/UnioptV1Factory.sol



pragma solidity ^0.8.0;
contract UnioptV1Factory  {
    using SafeMath for uint;
    address public feeTo;
    address public feeToSetter;

    event OptionsCreated( address indexed owner, uint indexed deadline, address options, uint prices);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
        feeTo = msg.sender;
    }
    

    function CodeHash() external pure returns (bytes32) {
        return keccak256(type(ETHOptions).creationCode);
    }

    function createETHOptions(uint _deadline, uint _price, address _owner) payable external  returns (address options) {
        uint deadline = uint(block.timestamp).add(_deadline.mul(24).mul(60).mul(60));
        bytes memory bytecode = type(ETHOptions).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_deadline, _price));
        assembly {
            options := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //(address _caller, uint256 _deadline, uint256 _price)
        uint amount = uint(msg.value).mul(997) / 1000;
        ETHOptions(options).initialize{value:amount}(_owner, deadline, _price);
        
        emit OptionsCreated(_owner, _deadline, options, _price);
    }

    function setFeeTo(address _feeTo) external  {
        require(msg.sender == feeToSetter, 'Uniopt: FORBIDDEN');
        feeTo = _feeTo;
    }


    function setFeeToSetter(address _feeToSetter) external  {
        require(msg.sender == feeToSetter, 'Uniopt: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function takeFee() public{        
        (bool success, ) = feeTo.call{value: address(this).balance}(new bytes(0));
        require(success, 'STE');
    }
}