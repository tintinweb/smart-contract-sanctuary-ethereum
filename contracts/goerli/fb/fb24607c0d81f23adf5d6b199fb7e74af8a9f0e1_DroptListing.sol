/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT LICENSE

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: DroptListing.sol



pragma solidity ^0.8.0;


contract DroptListing is ReentrancyGuard {
    uint256 listingFee = 0.0025 ether;
    address owner;
    

    //Define a Nft drop object
    struct Drop {
        string imageUri;
        string name;
        string description;
        string chain;
        string social_1;
        string social_2;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;        
        bool approved;
          
    }

    bool approved = false;
    
// "https://img.seadn.io/files/a41803ffbac10336b05367df826f2d99.png?auto=format&w=600",
// "Test Collection",
// "This is my drop this month",
// "twitter",
// "https://testtest.com",
// "faffaf",
// "0.05",
// "22",
// 1234567890,
// 1234567890,
// "ethereum",
// false

    //Get Listing fee
    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    // Create a list to hold the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    //Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public payable nonReentrant {
        _drop.approved = false; 
        drops.push(_drop);          
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
        require(listingFee> 0, "Amount must be higher than 0");
        require(msg.value == listingFee, "Please allow transfer of 0.0025 eth for listing fee.");
        payable(msg.sender); payable(address(this)); listingFee;

    }
    
    //Update from the nft drops list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of this listing");
            _drop.approved = false;
            drops[_index] = _drop;     
    }
    //Remove drop object
    // function unListDrop(
    // uint256 _index, Drop memory _drop)public {
    //     require(msg.sender == owner, "You are not the Father.");
    // }

    //Approve drop object to enable displaying
    function setApproveDrop(uint256 _index, bool _state) public {
        require(msg.sender == owner, "You are not the Father.");
        Drop storage drop = drops[_index];
        drop.approved = _state;
    }

    // function removeDrop(uint256 _index) public {
    //     require(msg.sender == owner, "You are not the Father.");
    //     Drop storage drop = drops[_index];
    //     drop.remove = false;
    // }

    function getBalance() external view returns (uint256) {
        require(msg.sender == owner, "You are not the Father.");
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the father.");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success);

        // This will split payment and send 5% to other address
        // (bool hs, ) = payable(OWNERS WALLET ADDRESS).call{value: address(this).balance * 5 / 100}("");
    }

    //Must set cost in WEI
    
    function setListingFee(uint256 _listingFee) public onlyOwner {
        require(msg.sender == owner, "You are not the father.");
        listingFee = _listingFee;
    }

    

    //Clear out all drop objects from list
}