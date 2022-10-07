// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IFarming.sol";
import "./INFT.sol";
import "./SignRecovery.sol";

/*
* @title ShoefyFarm
* @author Usman Fazil
* @notice Shoefy Farming contract
*/

contract ShoefyFarm is Ownable, IShoefyFarm, SignRecovery {
    uint256 public farmId;

    bytes32 public constant generalFarm = keccak256("GENERAL");
    bytes32 public constant rapidFarm = keccak256("RAPID");

    // farm category => nfts left
    mapping(bytes32 => uint256) public generalFarmsLeft;
    mapping(bytes32 => uint256) public rapidFarmsLeft;
    // farm category => staking tokens required
    mapping(bytes32 => uint256) public generalTokensRequired;
    mapping(bytes32 => uint256) public rapidTokensRequired;
    // time required for each category
    mapping(bytes32 => uint256) public generalFarmTime;
    mapping(bytes32 => uint256) public rapidFarmTime;
    // max farms allowed per category
    mapping(bytes32 => uint256) public generalFarmsAllowed;
    mapping(bytes32 => uint256) public rapidFarmsAllowed;
    // mappings to store farm information
    mapping(uint256 => address) public farmOwner;
    mapping(uint256 => uint256) public farmTimestamp;
    mapping(uint256 => bytes32) public farmCategory;
    mapping(uint256 => bytes32) public farmType;
    mapping(uint256 => bool) public farmHarvested;

    mapping(bytes => bool) private usedSign;
    mapping(address => mapping(bytes32 => uint256))public generalFarmsUsed;
    mapping(address => mapping(bytes32 => uint256))public rapidFarmsUsed;


    address public signerAddress;
    IERC20 internal shoefyToken;
    INFT internal nftContract;

    constructor(
        address shoefyContract_,
        address nftContract_,        
        string[] memory categories_,
        uint256[] memory totalGeneralNFTs,
        uint256[] memory totalRapidNFTs,
        uint256[] memory generalFarmsAllowed_,
        uint256[] memory rapidFarmsAllowed_,
        uint256[] memory generalTokensRequired_,
        uint256[] memory rapidTokensRequired_,
        address _signerAddress
    ) {
        require(
            _signerAddress != address(0),
            "Signer Address could not be empty"
        );
        farmId = 1;
        shoefyToken = IERC20(shoefyContract_);
        nftContract = INFT(nftContract_);

        signerAddress = _signerAddress;
        bytes32 category_;

        for (uint256 i = 0; i < categories_.length; i++) {
            category_ = keccak256(abi.encodePacked(categories_[i]));
            generalFarmsLeft[category_] = totalGeneralNFTs[i];
            rapidFarmsLeft[category_] = totalRapidNFTs[i];
            generalTokensRequired[category_] = generalTokensRequired_[i];
            rapidTokensRequired[category_] = rapidTokensRequired_[i];
            generalFarmsAllowed[category_] = generalFarmsAllowed_[i];
            rapidFarmsAllowed[category_] = rapidFarmsAllowed_[i];
        }

    }

    /*
    * @dev farm new Shoefy NFTs
    * @param category_ category of farm 
    * @param farmAmount_ total number of NFTs to farm
    * @param generalFarm_ bool value to check the type of farm (true for general, false for rapid)
    * @notice approve shoe tokens to farming contract before calling farm funciton
    */
    function farmNFT(bytes32 category_, uint256 farmAmount_, bool generalFarm_)
        external
        override
    { 
        _farmValidation(category_, farmAmount_, generalFarm_);

        bytes32 userFarmType;
        uint256 shoeAmount;
        generalFarm_ ? userFarmType = generalFarm : userFarmType = rapidFarm;
        

        for (uint256 i = 0; i < farmAmount_; i++) {
            uint256 newFarmId = _getNextFarmId();
            farmTimestamp[newFarmId] = block.timestamp;
            farmOwner[newFarmId] = msg.sender;
            farmCategory[newFarmId] = category_;

            farmType[newFarmId] = userFarmType;
             _incrementFarmId();

            if (generalFarm_){
                _decrementGeneralFarm(category_);
                shoeAmount += generalTokensRequired[category_];
                generalFarmsUsed[msg.sender][category_] += 1;
                emit GeneralNFTFarmed(msg.sender, category_, newFarmId);
            }else{
                _decrementRapidFarm(category_);
                shoeAmount += rapidTokensRequired[category_];
                rapidFarmsUsed[msg.sender][category_] += 1;
                emit RapidNFTFarmed(msg.sender, category_, newFarmId);
            }
        }

        require(
            shoefyToken.transferFrom(msg.sender, address(this), shoeAmount), "Token transfer failed" );
    }

    /*
    * @dev harvest user's farms 
    * @param farmIds_ array of farm ids 
    * @param tokenURIs_ array of token uris. 
    * @param signatures_ array of signatures created by admin for verification
    * @param generalFarm_ bool value to check the type of farm (true for general, false for rapid)
    * @notice function will call shoefyNFT contract batchMint function to mint new NFTs.
    */
    function harvestNFT(uint256[] memory farmIds_,string[] memory tokenURIs_,bytes[] memory signatures_,bool generalFarm_) external override {
        require(farmIds_.length == tokenURIs_.length && tokenURIs_.length == signatures_.length, "Invalid array length");
        
        bytes32 userFarmType;
        generalFarm_ ? userFarmType = generalFarm : userFarmType = rapidFarm;
        uint256 shoeAmount;

        for (uint256 i = 0; i < farmIds_.length; i++) {
            _harvestValidation(msg.sender,farmIds_[i], userFarmType, tokenURIs_[i], signatures_[i]);
            
            farmHarvested[farmIds_[i]] = true;
            usedSign[signatures_[i]] = true;

            if (generalFarm_){
                shoeAmount += generalTokensRequired[farmCategory[farmIds_[i]]];
                emit GeneralNFTMinted(msg.sender, farmCategory[farmIds_[i]], farmIds_[i]);
            }else{
                shoeAmount += rapidTokensRequired[farmCategory[farmIds_[i]]];                
                emit RapidNFTMinted(msg.sender, farmCategory[farmIds_[i]], farmIds_[i]);
            }
        }
        require(
            shoefyToken.transfer(msg.sender, shoeAmount), "Token transfer failed" );

        nftContract.mintBatch(msg.sender, tokenURIs_);
    }

    // admin function to update the address of message signer.
    function updateSignerAddress(address _signerAddress) public onlyOwner {
        require(
            _signerAddress != address(0),
            "Signer Address could not be empty"
        );
        signerAddress = _signerAddress;
    }

    // internal helper functions
    function _getNextFarmId() internal view returns (uint256) {
        return farmId;
    }

    function _incrementFarmId() internal {
        farmId += 1;
    }

    function _decrementGeneralFarm(bytes32 category_) internal {
        generalFarmsLeft[category_] -= 1;
    }

    function _decrementRapidFarm(bytes32 category_) internal {
        rapidFarmsLeft[category_] -= 1;
    }

    // internal function to verify the user provided signature
    function _verifySign(address userAddress_, uint256 farmId_,string memory tokenURI_, 
            bytes memory sign_)internal view returns (bool verfied){

        address recoveredAddress = recoverSigner(
            keccak256(abi.encodePacked(userAddress_, farmId_, tokenURI_)),sign_ );

        (recoveredAddress == signerAddress) ? verfied = true : verfied = false;

        return verfied;
    }

    // internal function to validate farm function parameters 
    function _farmValidation(bytes32 category_, uint256 farmAmount_, bool generalFarm_)internal view{

        if (generalFarm_){
            require(generalFarmsUsed[msg.sender][category_] + farmAmount_ <= generalFarmsAllowed[category_], "Can not farm more than allowed limit");
            require( generalFarmsLeft[category_] > 0, "General Farm limit reached for provided category");
        }else{
            require(rapidFarmsUsed[msg.sender][category_] + farmAmount_ <= rapidFarmsAllowed[category_], "Can not farm more than allowed limit");
            require( rapidFarmsLeft[category_] > 0, "Rapid Farm limit reached for provided category");
        } 
    }

    // internal function to validate the parameters and farm state before harvestation
    function _harvestValidation(
        address user_, 
        uint256 farmId_, 
        bytes32 farmType_,
        string memory tokenURI_,
        bytes memory sign_
        )internal view{

        require(farmOwner[farmId_] == user_,"Only owner can harvest the farm");
        require(farmType[farmId_] == farmType_, "Invalid farm type");
        require(!usedSign[sign_], "Signature already used");

        uint256 timeDiff = block.timestamp - farmTimestamp[farmId_];
        bytes32 category = farmCategory[farmId_];

        if (farmType_ == generalFarm){
            require(timeDiff > generalFarmTime[category], "Can not harvest during farming period");
        }else{
            require(timeDiff > rapidFarmTime[category], "Can not harvest during farming period");
        }

        require(_verifySign(user_, farmId_, tokenURI_, sign_), "Invalid signature");
    }

    function getUserLimit(bytes32 category_, bool generalFarm_)public view returns(uint256){
        if (generalFarm_){
            return (generalFarmsAllowed[category_] - generalFarmsUsed[msg.sender][category_]);
        }else{
            return (rapidFarmsAllowed[category_] -  rapidFarmsUsed[msg.sender][category_]);
        }
    }

    function updateConfig(
        string[] memory categories_,
        uint256[] memory totalGeneralNFTs,
        uint256[] memory totalRapidNFTs,
        uint256[] memory generalFarmTime_,
        uint256[] memory rapidFarmTime_,
        uint256[] memory generalFarmsAllowed_,
        uint256[] memory rapidFarmsAllowed_,
        uint256[] memory generalTokensRequired_,
        uint256[] memory rapidTokensRequired_
    )external onlyOwner{
        bytes32 category_;

        for (uint256 i = 0; i < categories_.length; i++) {
            category_ = keccak256(abi.encodePacked(categories_[i]));
            generalFarmsLeft[category_] = totalGeneralNFTs[i];
            rapidFarmsLeft[category_] = totalRapidNFTs[i];
            generalFarmTime[category_] = generalFarmTime_[i];
            rapidFarmTime[category_] = rapidFarmTime_[i];
            generalTokensRequired[category_] = generalTokensRequired_[i];
            rapidTokensRequired[category_] = rapidTokensRequired_[i];
            generalFarmsAllowed[category_] = generalFarmsAllowed_[i];
            rapidFarmsAllowed[category_] = rapidFarmsAllowed_[i];
        }
    }

}

// SPDX-License-Identifier: MIT
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IShoefyFarm{

    event GeneralNFTFarmed(address userAddress,bytes32 category,uint256 farmId);
    event RapidNFTFarmed(address userAddress,bytes32 category,uint256 farmId);
    event GeneralNFTMinted(address userAddress,bytes32 category,uint256 farmId);
    event RapidNFTMinted(address userAddress,bytes32 category,uint256 farmId);

// function for general and rapid farming of shoefy NFT
    function farmNFT(bytes32 category_, uint256 farmAmount_, bool generalFarm_) external;

// function to harvest NFT once it is farmed through general or rapid farming
    function harvestNFT(uint256[] memory farmIds_, string[] memory tokenURIs_, bytes[] memory signatures_, bool generalFarm) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract INFT {
    function mint(address to, string memory tokenURI) external virtual returns (uint256) {}

    function mintBatch(address to, string[] memory tokenURIs) external virtual {}

    function getNFTType(uint256 tokenId) external view virtual returns (uint256 nftType) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SignRecovery{
    
    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        message = prefixed(message);
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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