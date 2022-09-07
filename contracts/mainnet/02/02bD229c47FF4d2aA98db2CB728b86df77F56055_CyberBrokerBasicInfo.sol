// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICyberBrokers.sol";
import "./ICyberBrokersMetadata.sol";

contract CyberBrokerBasicInfo is Ownable{

    address public cyberbrokers = 0x892848074ddeA461A15f337250Da3ce55580CA85;

    struct CyberBrokerBasicMeta {
        string name;
        string talent;
        string gender;
        string background;
        string species;
        string class;
        string description;
        uint256 mind;
        uint256 body;
        uint256 soul;
    }

    constructor() {
    }

    function contains (string memory what, string memory source) internal pure returns(bool) {
        bytes memory whatBytes = bytes (what);
        bytes memory sourceBytes = bytes (source);

        require(sourceBytes.length >= whatBytes.length);

        bool found = false;
        for (uint i = 0; i <= sourceBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (sourceBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }

    function setCyberBrokersAddress(address addr) public onlyOwner {
        cyberbrokers = addr;
    }

    function getMetadataContract() public view returns(ICyberBrokersMetadata){
        address addr = ICyberBrokers(cyberbrokers).cyberBrokersMetadata();
        return ICyberBrokersMetadata(addr);
    }

    function getBasicMetadata(uint256 tokenId) public view returns (CyberBrokerBasicMeta memory metadata) {
        ICyberBrokersMetadata metadataContract = getMetadataContract();


        ///@dev Get the easiest info
        ICyberBrokersMetadata.CyberBrokerTalent memory talent = metadataContract.getTalent(tokenId);
        string memory cbName = metadataContract.getBrokerName(tokenId);
        metadata.name = cbName;
        metadata.talent = talent.talent;
        metadata.species= talent.species;
        metadata.class= talent.class;
        metadata.description= talent.description;

        (uint256 mind,uint256 body,uint256 soul)= metadataContract.getStats(tokenId);
        metadata.mind= mind;
        metadata.body= body;
        metadata.mind= soul;

        ///@dev get sex and background;
        uint256[] memory layerIds = metadataContract.getLayers(tokenId);
        uint256 backgroundLayerId = layerIds[0];
        uint256 genderLayerId = layerIds[1];

        ICyberBrokersMetadata.CyberBrokerLayer memory backgroundLayer = metadataContract.layerMap(backgroundLayerId);
        ICyberBrokersMetadata.CyberBrokerLayer memory genderLayer = metadataContract.layerMap(genderLayerId);

        metadata.background = backgroundLayer.key;


        if(contains("female-",genderLayer.key)){
            metadata.gender = "Female";
        }else if (contains("male-",genderLayer.key)){
            metadata.gender = "Male";
        }else{
            metadata.gender = "NA";
        }

        return metadata;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface ICyberBrokersMetadata {
    struct CyberBrokerLayer {
        string key;
        string attributeName;
        string attributeValue;
    }

    function layerMap(uint256 layerId) external view returns(CyberBrokerLayer memory);
        
    // Mapping of all talents
    struct CyberBrokerTalent {
        string talent;
        string species;
        string class;
        string description;
    }
    function getBrokerName(uint256 _tokenId) external view returns (string memory);
    function getStats(uint256 tokenId) external view returns (uint256 mind, uint256 body, uint256 soul);
    function talentMap(uint256 talentId) external view returns(CyberBrokerTalent memory);
    function brokerDna(uint256 tokenId) external view returns(uint256);
    function getTalent(uint256 tokenId) external view returns (CyberBrokerTalent memory talent);
    function getLayers(uint256 tokenId) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external;
      function renderBroker(
    uint256 _tokenId,
    uint256 _startIndex
  )
    external
    view
    returns (
      string memory,
      uint256
    );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.14;

interface ICyberBrokers {
    function cyberBrokersMetadata() external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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