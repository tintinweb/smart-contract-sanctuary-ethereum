//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract QrContract {
    address internal defaultOwner;

    address internal owner;

    address internal tenant;

    ///@dev user mapped to array of IPFS URI's that holds their QR Code metadata
    mapping(address => string[]) internal userMappedToIPFS;

    ///@dev Event for front end after qrcode is created
    event QrCodeCreated(string redirectFromUrl, bytes slug, address owner);

    constructor() {
        owner = msg.sender;
        defaultOwner = msg.sender;
    }

    /**
        @notice Creates QR code for the current tenant
        @param ipfsURI is the IPFS CID pointing to  {owner_wallet_id = QR[]}
        @param ownerAccount is current owners wallet address
     
    * */
    function createTenantQrCode(
        string calldata ipfsURI,
        address tenantAccount,
        address ownerAccount
    ) public {
        require(owner == ownerAccount, "Authorization Error : Owner doesnt match caller");
        if(tenant== address(0)){
            tenant = tenantAccount;
        }
        userMappedToIPFS[tenantAccount].push(ipfsURI);
    }

    /**
        @notice Creates QR code for the current owner
        @param ipfsURI is the IPFS CID pointing to  {owner_wallet_id = QR[]}
        @param ownerAccount is current owners wallet address
     
    * */
    function createOwnerQrCode(string calldata ipfsURI, address ownerAccount)
        public
    {
        require(owner == ownerAccount, "Authorization Error : Owner doesnt match caller");
        userMappedToIPFS[ownerAccount].push(ipfsURI);
    }

    /**
        @notice Returns array of QrCodes for the user
    * */
    function getAllQrCodeForUser(address account)
        public
        view
        returns (string[] memory)
    {
        require(owner == account, "Authorization Error : Owner doesnt match caller");
        return userMappedToIPFS[account];
    }

    /**
        @dev Changes tenant of the contract. Only current owner can change the tenant.
    * */
    function changeTenant(address account, address tenantAddress) internal {
        require(owner == account, "Authorization Error : Owner doesnt match caller");
        tenant = tenantAddress;
    }

    /**
        @dev Changes tenant of the contract. Only current owner can change the tenant.
    * */
    function changeOwner(address account, address newOwner) public {
        require(owner == account, "OAuthorization Error : wner doesnt match caller");
        owner = newOwner;
    }
}