// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./utils/Whitelist.sol";
import "./utils/MintingPhases.sol";

/**
* @dev Interface allowing to interact with the NFT contract
*/
interface MetawinNFTI{
    /**
    * @dev Token mint. As no second argument is allowed, will mint the next available tokenId.
    * @param to receiver address
    */
    function mint(address to) external;
    /**
    * @dev Get the current supply (total minted tokens).
    */
    function totalSupply() view external returns(uint256);
    /**
    * @dev Get the maximum supply.
    */
    function MAX_SUPPLY() view external returns(uint256);
}

/** @dev Contract defining Metawin NFT minting environments
  * Rules: TODO: UPDATE THIS COMMENT
  *     Multiple phases (freemints only, freemints + whitelisted, open to everyone)
  *     Each phase has a timer - admin can manually end the current phase.
  *     Free minting if in freemint list
  *     Max 5 paid mints per address during whitelist phase
  *     Additional 5 paid mints per address during open phase
  *     Price: variable during this test, TBC
*/
contract MetawinNFTMinter is MintingPhases, Ownable, Pausable, ReentrancyGuard {

    using Clones for address;

    // CONTRACT VARIABLES //
    uint256[] public price = [                   /// @notice: Prices (in ether) - rough implementation to demonstrate rules-based pricing
        0.01 ether, 
        0.0115 ether,
        0.0125 ether,
        0.015 ether,
        0.02 ether,
        0.025 ether];
    uint256 public priceStep = 2000;               // In this example, price increases every 2000 mints

    uint256 constant limitPerAddress = 5;         // Maximum mints per address
    mapping (address => uint256) minted;          // Track number of tokens minted by each address
    address public NFTcontract;
    address public payoutAddress = 0x1544D2de126e3A4b194Cfad2a5C6966b3460ebE3; // metawin.eth

    Whitelist immutable public whitelistContract; // Contract that handles the whitelist
    Whitelist immutable public freemintContract;  // Contract that handles the freemint list
    uint256 public freemints_reserved = 500;      // Max tokens reserved to freemint wallets

    constructor(){
        whitelistContract = new Whitelist();      // Deploy the whitelist contract
        freemintContract = Whitelist(address(whitelistContract).clone()); // Deploy the freemintList contract as a clone - save gas
        freemintContract.initialize();            // Also initialize it - cloning doesn't call the constructor
    }


    // SETUP //

    /**
    * @dev [Tx][Public][Owner] Link this contract to the NFT contract
    * @param _NFTcontract Address of the NFT contract
    */
    function setNFTaddress(address _NFTcontract) public onlyOwner {
        NFTcontract = _NFTcontract;
    }

    /**
    * @dev [Tx][Public][Owner] Set the address that will receive the payments
    * @param _address Payments will be routed to this
    */
    function setPayoutAddress(address _address) public onlyOwner {
        payoutAddress = payable(_address);
    }

    /**
    * @dev [Tx][Public][Owner] Set price step
    * @param step Number of mints triggering the next price increase
    */
    function setPriceStep(uint256 step) public onlyOwner {
        priceStep = step;
    }

    /**
    * @dev [Tx][Public][Owner] Set the phases times
    * @param _freemint_startTime Start time: freemints (in Unix timestamp)
    * @param _whitelist_delay Freemint phase duration (in minutes)
    * @param _open_delay Whitelist-only phase duration (in minutes)
    * @param _end_delay Open-mint phase duration (in minutes)
    */
    function phase_setTimes (
        uint256 _freemint_startTime, 
        uint256 _whitelist_delay, 
        uint256 _open_delay,
        uint256 _end_delay)
        public onlyOwner {
            super._phase_setTimes(_freemint_startTime, _whitelist_delay, _open_delay, _end_delay);
        }

    /**
    * @dev [Tx][Public][Owner] End the current phase now (and start the next one)
    */    
    function phase_endCurrent() public onlyOwner {
        super._phase_endCurrent();
    }

    
    // FREEMINT //

    /**
    * @dev [Tx][Public][Owner] Store the merkle root of the freemint list
    * @param _merkleRoot Merkle root hash
    */
    function freemint_setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        freemintContract.setMerkleRoot(_merkleRoot);
    }

    /**
    * @dev [View][Public] Check if the queried address in the freemint list
    * @param _address Address to check
    * @param _tickets Number of tickets, must match the number on the list.
    * @param _merkleProof Merkle proof
    */
    function freemint_isInList(address _address, uint8 _tickets, bytes32[] calldata _merkleProof) public view returns(bool) {
        return freemintContract.isInWhitelist(_address, _tickets, _merkleProof);
    }

    /**
    * @dev [View][Public] Check if the queried address has already claimed his freemint
    * @param _address Address to check
    */
    function freemint_hasClaimed(address _address) public view returns(bool) {
        return freemintContract.getUsedAllowance(_address)>0;
    }

    /**
    * @dev [Tx][Public] Free minting
    * @param _merkleProof Merkle proof
    */
    function mintFree(uint8 _tickets, bytes32[] calldata _merkleProof) public whenNotPaused {
        require(phase_current()>MintingPhase(0));
        require(freemintContract.isInWhitelist(msg.sender, _tickets, _merkleProof), "Address not in freemint list");
        require(freemintContract.getUsedAllowance(msg.sender) == 0, "Already claimed");
        freemintContract.claim(msg.sender, _tickets, _merkleProof, _tickets);
        //minted[msg.sender] += _tickets; //Currently not used as freemints don't have to erode allocation
        freemints_reserved -= _tickets;
        for (uint256 n; n<_tickets; n++){
            MetawinNFTI(NFTcontract).mint(msg.sender);
        }
    }


    // WHITELIST //
    
    /**
    * @dev [Tx][Public][Owner] Store the merkle root of the whitelist
    * @param _merkleRoot Merkle root hash
    */
    function whitelist_setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistContract.setMerkleRoot(_merkleRoot);
    }

    /**
    * @dev [View][Public] Check if the queried address in the whitelist
    * @param _address Address to check
    * @param _merkleProof Merkle proof
    */
    function whitelist_isInList(address _address, bytes32[] calldata _merkleProof) public view returns(bool) {
        return whitelistContract.isInWhitelist(_address, _merkleProof);
    }


    // PURCHASE //

    /**
    * @dev [View][Public] Return how many tokens can still be minted
    */
    function mintableSupply() public view returns(uint256){
        return MetawinNFTI(NFTcontract).MAX_SUPPLY() - 
            MetawinNFTI(NFTcontract).totalSupply() -
            freemints_reserved;
    }

    /**
    * @dev [View][Public] Get current price
    */
    function currentPrice() public view returns(uint256) {
        return price[MetawinNFTI(NFTcontract).totalSupply()/priceStep];
    }

    /**
    * @dev [Tx][Public][PAYABLE] Paid minting
    * @param amount Number of tokens to mint
    */
    function mintBuy(uint256 amount, bytes32[] calldata _whitelist_merkleProof) public payable nonReentrant whenNotPaused {
        //Checks
        uint8 curPhase = uint8(phase_current());
        require(curPhase==2 || curPhase==3, "Not allowed during current phase");
        require(amount <= mintableSupply(), "Not enough tokens available to mint");
        require((amount + minted[msg.sender]) <= ((curPhase - 1)*limitPerAddress), "Exceeding allocation"); // x2 limit in open phase
        require(currentPrice()*amount == msg.value, "Price paid incorrect");
        if(curPhase == 2) 
            require(whitelist_isInList(msg.sender, _whitelist_merkleProof), "Not in whitelist");
        //Purchase
        (bool paid, ) = payoutAddress.call{value: address(this).balance}("");
        require(paid);
        //Mint
        minted[msg.sender] += amount;
        for(uint256 i; i<amount; i++){
            MetawinNFTI(NFTcontract).mint(msg.sender);
        }
    }


    // PAUSE //

    /**
    * @dev [Tx][Public][Owner] Pause the contract
    */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
    * @dev [Tx][Public][Owner] Unpause the contract
    */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/** @dev Contract providing an address whitelisting feature (using merkleProof).
 *  It is meant to be deployed as an instance (by using the "new" command): this approach allows to have
 *  multiple lists in the same contract.
 *  To optimize the gas usage, it is recommended to deploy only the first instance with the "new" command
 *  and use minimalProxies (aka clones - EIP-1167) for the others.
 *  The contract can be used in two ways:
 *  (1) With a list containing only addresses: the contract variable "allowance" will be used - and can also be set
 *  (2) With a list containing both addresses and allowances: call the alternative functions with the additional
 *  "_listAllowance" input. These functions ignore the allowance variable and rely on the _allowance parameter.
 *  Note: each function is flagged with (1), (2) or (1)(2), depending on which methodology they are meant to be
 *  used with.
*/
contract Whitelist {

    uint8 private allowance=1;                  // Allowance for each member of the list - defaults to 1
    mapping(address => uint8) private used;     // User address => Counter
    bytes32 private merkleRoot;                 // MerkleRoot for whitelist membership verification
    address private deployer;                   // Store the deployer address to restrict some functions

    constructor(){
        initialize();
    }

    modifier onlyDeployer{
        require(msg.sender == deployer, "Access restricted to deployer");
        _;
    }

    /**
     * @dev (1)(2) This function acts like a constructor but it's compatible
     * with proxy contracts (clones, upgradable, etc.). Must be called by deployer
     * as soon as the instance is created. If the contract has been deployed normally,
     * there is no need to call this as it is also wrapped in the actual constructor.
     */
    function initialize() public {
        require(deployer == address(0), "Already initialized");
        deployer = msg.sender;
    }

    /**
     * @dev (1) Checks if the address is in the whitelist.
     * @param _address Address to be checked
     * @param _merkleProof Merkle proof
     */
    function isInWhitelist(address _address, bytes32[] calldata _merkleProof) view public returns(bool){
        bytes32 leaf = keccak256(abi.encode(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev (2) Overload of the previous function with an additional parameters for the allowance
     * To be used when the allowance is reported in the list
     * Each item in the list must be formatted as follows: "[address]:[allowance]"
     * @param _address Address to be checked
     * @param _listAllowance Allowance as reported in the whitelist
     * @param _merkleProof Merkle proof
     */
    function isInWhitelist(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof) view public returns(bool){
        bytes32 leaf = keccak256(abi.encode(_address, ":", _listAllowance));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev (1) Returns the total allowance of the queried address, zero if not in whitelist
     * @param _address Address to be checked
     * @param _merkleProof Merkle proof
     */
    function getAllowance(address _address, bytes32[] calldata _merkleProof) view public returns(uint8){
        if (isInWhitelist(_address, _merkleProof)) return allowance;
        else return 0;
    }
    
    /**
     * @dev (1)(2) Returns the allowance used by the queried address
     * @param _address Address to be checked
     */
    function getUsedAllowance(address _address) view public returns(uint8){
        return used[_address];
    }
    
    /**
     * @dev (1) Returns the allowance available to the queried address
     * @param _address Address to be checked
     * @param _merkleProof Whitelist merkle proof
     */
    function getUnusedAllowance(address _address, bytes32[] calldata _merkleProof) view public returns(uint8){
        uint8 addressAllowance = getAllowance(_address, _merkleProof);
        return used[_address] < addressAllowance ? addressAllowance-used[_address] : 0;
    }

    /**
     * @dev (2) Alternative method to be used when the allowance is reported in the original list
     * Important: in the input allowance specified is wrong, the return value will be zero as
     * each [address]:[allowance] pair is a unique list element
     * @param _address Address to be checked
     * @param _listAllowance Allowance as reported in the whitelist
     * @param _merkleProof Whitelist merkle proof
     */
    function getUnusedAllowance(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof) view public returns(uint8){
        if (!isInWhitelist(_address, _listAllowance, _merkleProof)){
            return 0;
        }
        else{
            return used[_address] < _listAllowance ? _listAllowance-used[_address] : 0;
        }
    }

    /**
     * @dev (1)(2) Stores the whitelist merkle root
     * @param _merkleRoot Merkle root to be stored
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyDeployer {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev (1) Changes the whitelist allowance
     * @param _allowance New allowance per address
     */
    function setAllowance(uint8 _allowance) public onlyDeployer {
        allowance=_allowance;
    }

    /**
     * @dev (1) Use the whitelist allowance
     * @param _address Address claiming
     * @param _merkleProof Whitelist merkle proof
     */
    function claim(address _address, bytes32[] calldata _merkleProof) public onlyDeployer{
        require(getUnusedAllowance(_address, _merkleProof)>0, "Exceeding allowance");
        used[_address] += 1;
    }

    /**
     * @dev (2) Use the whitelist allowance, alternative with allowance input
     * @param _address Address claiming
     * @param _listAllowance Address allowance (as reported on the whitelist)
     * @param _merkleProof Whitelist merkle proof
     */
    function claim(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof) public onlyDeployer{
        require(getUnusedAllowance(_address, _listAllowance, _merkleProof)>0, "Exceeding allowance");
        used[_address] += 1;
    }

    /**
     * @dev (1) Use the whitelist allowance (more than one entry)
     * @param _address Address claiming
     * @param _merkleProof Whitelist merkle proof
     * @param _amount Amount to claim
     */
    function claim(address _address, bytes32[] calldata _merkleProof, uint8 _amount) public onlyDeployer{
        require(_amount<=getUnusedAllowance(_address, _merkleProof), "Exceeding allowance");
        used[_address] += _amount;
    }

    /**
     * @dev (2) Alternative specifying the allowance from the list
     * @param _address Address claiming
     * @param _listAllowance Address allowance (as reported on the whitelist)
     * @param _merkleProof Whitelist merkle proof
     * @param _amount Amount to claim
     */
    function claim(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof, uint8 _amount) public onlyDeployer{
        require(_amount<=getUnusedAllowance(_address, _listAllowance, _merkleProof), "Exceeding allowance");
        used[_address] += _amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.14;

/** @dev Base contract providing the logics for a multi-phase minting
*/
abstract contract MintingPhases {

    enum MintingPhase {setup, freemints, whitelist, openToAll, end}
    mapping (MintingPhase => uint256) public phaseStartTime;

    /**
    * @dev [View][Public] Get the current phase, based on block.timestamp
    */
    function phase_current() internal view returns(MintingPhase){
        if (phaseStartTime[MintingPhase.freemints] == 0) return MintingPhase(0);
        uint256 curTime = block.timestamp;
        for (uint8 phase=uint8(MintingPhase.end); phase>0; phase--){
            if(curTime > phaseStartTime[MintingPhase(phase)]) return MintingPhase(phase);
        }
        return MintingPhase(0);
    }

    /**
    * @dev [View][Public] Return the name of the current phase
    */
    function phase_nameOfCurrent() public view returns (string memory){
        string[5] memory phaseNames = ["Setup", "Freemints", "Whitelisted", "Open", "End"];
        return phaseNames[uint256(phase_current())];
    }

    /**
    * @dev [View][Public] Compute the current phase time left
    */
    function phase_timeToNext() public view returns(uint256){
        MintingPhase cur = phase_current();
        if(cur == MintingPhase.end || phaseStartTime[cur] == 0) return 0;
        else return phaseStartTime[MintingPhase(uint8(cur)+1)]-block.timestamp;
    }

    /**
    * @dev [Tx][Internal] Set the phases times
    * @param _freemint_startTime Start time: freemints (in Unix timestamp)
    * @param _whitelist_delay Freemint phase duration (in minutes)
    * @param _open_delay Whitelist-only phase duration (in minutes)
    * @param _end_delay Open-mint phase duration (in minutes)
    */
    function _phase_setTimes (
        uint256 _freemint_startTime, 
        uint256 _whitelist_delay, 
        uint256 _open_delay,
        uint256 _end_delay)
        internal virtual {
            require(uint8(phase_current()) == 0, "Locked since minting started");
            phaseStartTime[MintingPhase.freemints] = _freemint_startTime;
            phaseStartTime[MintingPhase.whitelist] = _freemint_startTime + (1 minutes *  _whitelist_delay);
            phaseStartTime[MintingPhase.openToAll] = phaseStartTime[MintingPhase.whitelist] + (1 minutes * _open_delay);
            phaseStartTime[MintingPhase.end] = phaseStartTime[MintingPhase.openToAll] + (1 minutes * _end_delay);
        }

    /**
    * @dev [Tx][Internal] End the current phase (and start the next one) immediately
    */    
    function _phase_endCurrent() internal virtual {
        phaseStartTime[MintingPhase(uint8(phase_current())+1)] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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