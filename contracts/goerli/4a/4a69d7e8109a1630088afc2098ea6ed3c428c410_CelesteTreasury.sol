/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/makerdao/dss/blob/1.3.0/src/dai.sol



// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Dai {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Dai/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string  public constant name     = "Dai Stablecoin";
    string  public constant symbol   = "DAI";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "Dai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad, "Dai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply    = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "Dai/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != type(uint).max) {
            require(allowance[usr][msg.sender] >= wad, "Dai/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply    = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }
    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Dai/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "Dai/permit-expired");
        require(nonce == nonces[holder]++, "Dai/invalid-nonce");
        uint wad = allowed ? type(uint).max : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/math/SafeMath.sol


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

// File: contracts/celeste_treasury_dai.sol



pragma solidity >=0.5.12 <0.8.17;



// Adding only the DaiToken ERC-20 functions required
interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

// Contract is owned, set withdrawalsAllowed and constructor
contract owned {
    DaiToken daitoken;
    address owner;

// Disable or enable deposits and withdraw
    bool public withdrawalAllowed;

    constructor() {
        owner = msg.sender;
        daitoken = DaiToken(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);
        withdrawalAllowed = false;
    }

// Set the onlyOwner modifer
    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

// Contract is owned by onlyOwner
contract mortal is owned {

// Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }
}

// Primary contract functions
contract CelesteTreasury is mortal {
    using SafeMath for uint256;

// Mapping to track the DAI balance of each user
    mapping (address => uint256) public userBalances;
    address [] users;

// The minimum and maximum deposit amounts and withdrawal fee
    uint256 public MIN_DEPOSIT = 500;
    uint256 public MAX_DEPOSIT = 1000000;
    uint256 public WITHDRAWAL_FEE = 5;

// The contract owner can pause the contract, preventing any further deposits or withdrawals
    function pause() public onlyOwner {
        require(msg.sender == owner, "Only the contract owner can pause the contract");
        selfdestruct(payable(msg.sender));
    }

// Only the contract owner can enable or disable withdrawals
    function setWithdrawalAllowed(bool _withdrawalAllowed) public onlyOwner {
        require(msg.sender == owner, "Only the contract owner can enable/disable withdrawals");
        withdrawalAllowed = _withdrawalAllowed;
    }

    event Withdraw(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

// Users can deposit DAI to the contract
    function deposit() public payable {
        bool withdrawalLock = false;

        // Access the contract's state before making the external call
        require(withdrawalAllowed, "Withdrawals are not currently allowed");
        require(msg.value >= MIN_DEPOSIT && msg.value <= MAX_DEPOSIT, "Invalid deposit amount");

        // Update the user's balance in the mapping
        userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);

        // Use a reentrancy lock to prevent untrusted callees from re-entering the contract
        require(!withdrawalLock, "Reentrancy detected");
        withdrawalLock = true;

        // Transfer the DAI to the contract
        require(daitoken.transfer(msg.sender, msg.value), "Transfer failed");

        // Unlock the contract to allow future withdrawals
        withdrawalLock = false;
    }

// Users can withdraw their DAI from the contract less the withdrawal fee
    function withdraw(uint withdraw_amount) public {

        // Declare the withdrawalLock variable
        bool withdrawalLock = false;

        // Access the contract's state before making the external call
        require(withdrawalAllowed, "Withdrawals are not currently allowed");
        require(userBalances[msg.sender] >= withdraw_amount, "Insufficient balance");
        require(userBalances[msg.sender] >= WITHDRAWAL_FEE, "Insufficient balance to cover withdrawal fee");

        // Use the withdrawalLock variable to prevent untrusted callees from re-entering the contract
        require(!withdrawalLock, "Reentrancy detected");
        withdrawalLock = true;

        // Transfer the requested DAI to the user, less the withdrawal fee
        address payable recipient = payable (msg.sender);
        require(daitoken.transfer(recipient, withdraw_amount.sub(WITHDRAWAL_FEE)), "Transfer failed");

        // Update the user's balance in the mapping
        userBalances[msg.sender] = userBalances[msg.sender].sub(withdraw_amount);
        emit Withdraw(msg.sender, withdraw_amount);

        // Unlock the contract to allow future withdrawals
        withdrawalLock = false;
    }

// User can check their balance
    function checkBalance() public view returns (uint256) {
        return userBalances[msg.sender];
    }

// Owner can withdraw all the DAI from contract
    function withdrawAll() public onlyOwner {
        require(msg.sender == owner, "Only the contract owner can withdraw all DAI from the contract");

        // Transfer all DAI to the contract owner
        uint withdraw_amount = daitoken.balanceOf(address(this));
        require(daitoken.transfer(owner, withdraw_amount), "Transfer failed");

        // Update the contract owner's balance in the mapping
        userBalances[owner] = userBalances[owner].add(withdraw_amount);
    }

// Reset all userBalances to 0
    function resetBalance(uint256 value) public onlyOwner {
        for (uint i=0; i< users.length ; i++){
        userBalances[users[i]] = value;
        }
    }

// Only the contract owner can refund all users
    function refund() public onlyOwner {

        // Iterate through the list of users
        for (uint i = 0; i < users.length; i++) {

        // Get the address of the current user
        address user = users[i];

        // Check if the user has a balance
        if (userBalances[user] > 0) {

        // Calculate the amount to refund
        uint refundAmount = userBalances[user].sub(WITHDRAWAL_FEE);

        // Transfer the refund amount to the user
        require (daitoken.transfer(user, refundAmount), "Transfer failed");

        // Emit a Withdraw event
        emit Withdraw(user, refundAmount);
        }
        }
    }
}