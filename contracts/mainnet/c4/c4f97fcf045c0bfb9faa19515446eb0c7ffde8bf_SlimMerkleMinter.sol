/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

/**
* @dev to mint POE tokens
 */
interface PoExtended{
    function mint(address) external returns (bool);
}

/**
* @title NFT
* @dev ERC721 contract that holds the bonus NFTs
 */
interface INFT{
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/**
* @title PoExtended
* @author Carson Case [[email protected]]
* @notice PoExtended is a POE token with owner delegated Admins and a merkle claim system
*/

/**
* @title MerkleMinter
* @author Carson Case > [email protected]
* @author Zane Huffman > @jeffthedunker
* @dev is ownable. For now, by deployer, but can be changed to DAO
 */

contract SlimMerkleMinter is Ownable{
    using MerkleProof for bytes32[];
    /// @dev the merkle root which CAN be updated
    bytes32 public merkleRoot;

    
    mapping(address => bool) admins;

    //Treasury address
    address payable public treasury;

    //Base commission rate for refferals. Decimal expressed as an interger with decimal at 10^3 place (1 = 0.1%, 10 = 1%).
    uint256 public baseCommission;

    //xGDAO address
    address public xGDAO;

    //POE address
    address public POEContract;

    //Cost to sign up
    uint256 public basePrice;

    //NFT bonus address
    address public bonusNFTAddress;

    //Free if a users holds this much xGDAO or more
    uint256 public minXGDAOFree;

    //Nft bonus info
    struct nftBonus{
        uint128 id;
        //Decimal expressed as an interger with decimal at 10^18 place.
        uint128 multiplier;
    }

    //Array of NFT bonus info
    nftBonus[] bonusNFTs; 

    /**
    * @notice arrays must have the same length 
    * @param _treasury address to receive payments
    * @param _basePrice for starting price
    * @param _bonusNFTAddress to look up bonus NFTs
    * @param _commission base referral commission before bonus
    * @param _bonusNFTIDs ids of bonus NFTs (length must match multipliers)
    * @param _bonusNFTMultipliers multipliers of bonus NFTs (length must match IDs) 100% is 10^18
     */
    constructor(
        address payable _treasury,
        address _xGDAOAddress,
        uint256 _basePrice,
        address _bonusNFTAddress,
        uint256 _commission,
        uint128[] memory _bonusNFTIDs,
        uint128[] memory _bonusNFTMultipliers
        ) 
        Ownable()
        {
        bonusNFTAddress = _bonusNFTAddress;
        _addBonusNFTs(_bonusNFTIDs, _bonusNFTMultipliers);

        treasury = _treasury;
        xGDAO = _xGDAOAddress;
        basePrice = _basePrice;
        baseCommission = _commission;

    }

    /// @dev some functions only callable by approved Admins
    modifier onlyAdmin(){
        require(admins[msg.sender], "must be approved by owner to call this function");
        _;
    }

     /// @dev only owner can add Admins
    function addAdmin(address _admin) external onlyOwner{
        require(admins[_admin] != true, "Admin is already approved");
        admins[_admin] = true;
    }

    /// @dev owner can remove them too
    function removeAdmin(address _admin) external onlyOwner{
        require(admins[_admin] != false, "Admin is already not-approved");
        admins[_admin] = false;
    }

    /// @dev A Admin can forefit their minting status (useful for contracts)
    function forefitAdminRole()external{
        require(admins[msg.sender] == true, "msg.sender must be an approved Admin");
        admins[msg.sender] = false;
    }

    /// @dev set xGDAO address
    function setXGDAOAddress(address _new) external onlyAdmin{
        xGDAO = _new;
    }

    /// @dev set POE Contract address
    function setPOEContractAddress(address _new) external onlyAdmin{
        POEContract = _new;
    }

    /// @dev set minXGDAO. If zero, no free amount
    function setMinXGDAOFree(uint _new) external onlyAdmin{
        minXGDAOFree = _new;
    }

    function updateMerkleRoot(bytes32 _new) external onlyAdmin{
        merkleRoot = _new;
    }
    /**
    * @notice purchase function. Can only be called once by an address
    * @param _referrer must have an auth token. Pass 0 address if no referrer
     */
    function purchasePOE(address payable _referrer, /*bytes32 _hashedRef,*/ bytes32[] memory proof) external payable{
		
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(proof.verify(merkleRoot,leaf), "Address not eligible for claim");

        address payable referrer = _referrer;

        uint256 price = basePrice;
        if(minXGDAOFree != 0 && IERC20(xGDAO).balanceOf(msg.sender) >= minXGDAOFree){
            price = 0;
        }

        require(msg.sender != _referrer, "You cannot use yourself as a referrer");
        require(msg.value == price, "You must pay the exact price to purchase. Call the getPrice() function to see the price in wei");

        if(price > 0){
            //Give commisson if there's a referrer
            if(referrer != address(0))
            {
                //Calculate commission and subtract from price to avoid rounding errors
                uint256 commission = getCommission(price, referrer);
                referrer.transfer(commission);
                treasury.transfer(price-commission);
                //If not, treasury gets all the price
            }else{
                treasury.transfer(price);
            }
        }

        //Mint a POE
        PoExtended(POEContract).mint(msg.sender);
    }

    /**
    * @notice for owner to change base commission
    * @param _new is new commission
     */
    function changeBaseCommission(uint256 _new) external onlyOwner {
        baseCommission = _new;
    }

    /**
    * @notice for owner to change the price curve contract address
    * @param _new is the new address
     */
    function setBasePrice(uint256 _new) external onlyAdmin{
        basePrice = _new;
    }
    
    /**
    * @notice for owner to add some new bonus NFTs
    * @dev see _addBonusNFTs
    * @param _bonusNFTIDs array of IDs
    * @param  _bonusNFTMultipliers array of multipliers
     */
    function addBonusNFTs(uint128[] memory _bonusNFTIDs, uint128[] memory _bonusNFTMultipliers) public onlyOwner{
        _addBonusNFTs(_bonusNFTIDs, _bonusNFTMultipliers);
    }
	
    /**
    * @notice function returns the commission based on base commission rate, NFT bonus, and price
    * @param _price is passed in, but should be calculated with getPrice()
    * @param _referrer is to look up NFT bonuses
    * @return the commission ammount
     */
    function getCommission(uint256 _price, address _referrer) internal view returns(uint256){
        uint128 bonus = getNFTBonus(_referrer);
        uint256 commission;
        if(bonus > 0){
            commission = baseCommission + ((baseCommission * bonus) / 1000);
        }else{
            commission = baseCommission;
        }      
        return((_price * commission) / 1000);
    }

    /**
    * @notice function to get the NFT bonus of a person
    * @param _referrer is the referrer address
    * @return the sum of bonuses they own
     */
    function getNFTBonus(address _referrer) public view returns(uint128){
        uint128 bonus = 0;
        INFT nft = INFT(bonusNFTAddress);
        //Loop through nfts and add up bonuses that the referrer owns
        for(uint8 i = 0; i < bonusNFTs.length; i++){
            if(nft.balanceOf(_referrer, bonusNFTs[i].id) > 0){
                bonus += bonusNFTs[i].multiplier;
            }
        }
        return bonus;
    }

    /**
    * @notice private function to add new NFTs as bonuses 
    * @param _bonusNFTIDs array of ids matching multipliers
    * @param _bonusNFTMultipliers array of multipliers matching ids
     */
    function _addBonusNFTs(uint128[] memory _bonusNFTIDs, uint128[] memory _bonusNFTMultipliers) private{
        require(_bonusNFTIDs.length == _bonusNFTMultipliers.length, "The array parameters must have the same length");
        //Add all the NFTs
        for(uint8 i = 0; i < _bonusNFTIDs.length; i++){
            bonusNFTs.push(
                nftBonus(_bonusNFTIDs[i],_bonusNFTMultipliers[i])
            );
        }
    }

}