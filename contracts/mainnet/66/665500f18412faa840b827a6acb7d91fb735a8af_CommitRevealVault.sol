/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    /**
    * Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * This event is triggered when a given amount of tokens is sent to an address.
     * @param from The address of the sender
     * @param to The address of the receiver
     * @param value The amount transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * This event is triggered when a given address is approved to spend a specific amount of tokens
     * on behalf of the sender.
     * @param owner The owner of the token
     * @param spender The spender
     * @param value The amount to transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Represents a resource that works per Commit-and-Reveal scheme with 4 passwords.
 */
contract CommitRevealVault {
    // The hash of the authorized caller
    bytes32 private _authorizedCaller;

    // The challenge to solve
    bytes32 private _challenge;

    // The reentrancy guard
    bool private _reentrancyGuard;

    /**
     * @notice This event is triggered when the authorized caller is updated.
     * @param previousCaller The hash of the previous caller
     * @param newCaller The hash of the new caller
     */
    event AuthorizedCallerChanged (bytes32 previousCaller, bytes32 newCaller);

    /**
     * @notice Constructor.
     * @param newChallenge The challenge to solve
     * @param newAuthorizedCaller The hash of the authorized caller
     */
    constructor (bytes32 newChallenge, bytes32 newAuthorizedCaller) {
        require(newAuthorizedCaller != bytes32(0), "Authorized caller required");
        require(newChallenge != bytes32(0), "Challenge required");

        _challenge = newChallenge;
        _authorizedCaller = newAuthorizedCaller;
    }

    /**
     * @notice Throws if called by an unauthorized sender.
     * @dev Calling this function requires impersonating the message sender.
     */
    modifier onlyAuthorizedCaller () {
        require(keccak256(abi.encodePacked(msg.sender, address(this))) == _authorizedCaller, "Unauthorized caller");
        _;
    }

    /**
     * @notice Throws in case of a reentrant call
     */
    modifier ifNotReentrant () {
        require(!_reentrancyGuard, "Reentrant call rejected");
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    /**
     * @notice Function to receive Ether. It is called if "msg.data" is empty
     * @dev Anyone is allowed to deposit Ether in this contract.
     */
    receive() external payable {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Fallback function for receiving Ether. It is called when "msg.data" is not empty
     * @dev Anyone is allowed to deposit Ether in this contract.
     */
    fallback() external payable {}

    /**
     * @notice Transfers ownership to another address.
     * @param newAuthorizedCaller The hash of the new authorized caller
     * @param newChallenge The new challenge
     * @param a Proof A
     * @param b Proof B
     * @param c Proof C
     * @param d Proof D
     */
    function transferOwnership (bytes32 newAuthorizedCaller, bytes32 newChallenge, bytes32 a, bytes32 b, bytes32 c, bytes32 d) 
    public onlyAuthorizedCaller ifNotReentrant {
        // Parameter checks
        require(newAuthorizedCaller != bytes32(0) && newAuthorizedCaller != _authorizedCaller, "Caller rotation required");
        require(newChallenge != bytes32(0) && newChallenge != _challenge, "Challenge rotation required");

        // Validate the challenge
        require(_challenge == keccak256(abi.encode(a, b, c, d)), "Invalid proof");

        // State changes
        emit AuthorizedCallerChanged(_authorizedCaller, newAuthorizedCaller);
        _authorizedCaller = newAuthorizedCaller;
        _challenge = newChallenge;
    }

    /**
     * @notice Runs a native transfer.
     * @param toAddress The payable destination address
     * @param toAmount The transfer amount
     * @param newChallenge The new challenge
     * @param a Proof A
     * @param b Proof B
     * @param c Proof C
     * @param d Proof D
     */
    function transferNative (address payable toAddress, uint256 toAmount, bytes32 newChallenge, bytes32 a, bytes32 b, bytes32 c, bytes32 d) 
    public onlyAuthorizedCaller ifNotReentrant {
        // Parameter checks
        require(toAddress != address(0), "Invalid address");
        require(toAmount > 0, "Invalid amount");
        require(newChallenge != bytes32(0) && newChallenge != _challenge, "Challenge rotation required");

         // Validate the challenge
        require(_challenge == keccak256(abi.encode(a, b, c, d)), "Invalid proof");

        // State changes
        _challenge = newChallenge;

        // Trusted native call, with gas limit.
        toAddress.transfer(toAmount);
    }

    /**
     * @notice Runs a token transfer per EIP20.
     * @param contractAddr The contract address
     * @param toAddress The destination address
     * @param toAmount The transfer amount
     * @param newChallenge The new challenge
     * @param a Proof A
     * @param b Proof B
     * @param c Proof C
     * @param d Proof D
     */
    function transferToken (IERC20 contractAddr, address toAddress, uint256 toAmount, bytes32 newChallenge, bytes32 a, bytes32 b, bytes32 c, bytes32 d) 
    public onlyAuthorizedCaller ifNotReentrant {
        // Parameter checks
        require(toAddress != address(0), "Invalid address");
        require(toAmount > 0, "Invalid amount");
        require(newChallenge != bytes32(0) && newChallenge != _challenge, "Challenge rotation required");

        // Validate the challenge
        require(_challenge == keccak256(abi.encode(a, b, c, d)), "Invalid proof");

        // Apply state changes prior making any external call, Check-Effect-Interactions
        _challenge = newChallenge;

        // Fire the untrusted external call
        require(contractAddr.transfer(toAddress, toAmount), "ERC20 transfer failed");
    }
}