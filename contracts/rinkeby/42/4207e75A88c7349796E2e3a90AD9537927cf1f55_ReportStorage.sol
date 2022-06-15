// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

contract ReportStorage is Ownable {
    // Variables

    uint256 image_hashes_id_counter = 170106;
    uint256 sample_report_id_counter = 64310;

    // Arrays

    // Structs
    // struct DetailedReports {
    // }

    struct SampleReports {
        uint256 report_id;
        string tested_url;
        uint256 mobile_score;
        uint256 desktop_score;
        uint256 image_hashes_id;
    }

    // Mappings
    mapping(uint256 => string[]) id_to_imagehashes;
    mapping(uint256 => SampleReports) id_to_samplereport;

    // Payable Functions

    function addSampleReport(
        string memory _tested_url,
        uint256 _mobile_score,
        uint256 _desktop_score,
        string[] memory _image_hashes
    ) public onlyOwner {
        SampleReports memory sample_rep = SampleReports(
            sample_report_id_counter,
            _tested_url,
            _mobile_score,
            _desktop_score,
            image_hashes_id_counter
        );

        id_to_imagehashes[image_hashes_id_counter] = _image_hashes;
        id_to_samplereport[sample_report_id_counter] = sample_rep;

        image_hashes_id_counter++;
        sample_report_id_counter++;
    }




    // View functions

    function getSampleReports(uint256 _sample_report_id) view public returns(SampleReports memory){
        return id_to_samplereport[_sample_report_id];
    }

    function getImageHashes(uint256 _image_hash_id) view public returns(string[] memory){
        return id_to_imagehashes[_image_hash_id];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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