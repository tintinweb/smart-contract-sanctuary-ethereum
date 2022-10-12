/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
enum ItemType {
    ERC20,
    ERC721,
    ERC1155,
    OTHER
}

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

interface IERC721 {
    function exist(uint tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address _owner) external view returns (uint256);
}

interface IERC1155 {
    function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract NFTOption is Ownable {


    address s_owner;

    // Config for the smart contract
    // Todo WETH_ADDRESS for Goerli
    address WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 betFee = 0.001 ether;
    uint256 public contractCommission = 25; // 2.5%
    bytes4 public constant ERC1155InterfaceId = 0xd9b67a26;
    bytes4 public constant ERC721InterfaceId = 0x80ac58cd;



    // 1. get available contract 
    OptionContract[] public allContracts;

    // 2. get finished contract 
    //    store all finished contract id in finishedcontractIDs when exercised, deactivated
    //    get the length of all finishedcontractIDs
    //    loop the array to get the IDs
    uint256[] public finishedcontractIDs; 


    // 3. get contract by user address
    //    store all contract finishedcontractIDs when exercised, deactivated
    //    get the length of all finishedcontractIDs
    //    loop the array to get the IDs
    mapping(address => uint256[]) public contractIDToHost;


    mapping(address => bool) public whitelistedAddresses; 
    mapping(bytes => bool) public allSignatures; 

    // EVENETS 
    event ContractCreated(uint contractID, address host, address nftAddr, uint256 nftID);
    event BuyContract(uint contractID, address player);
    event ContractExercised(uint contractID);
    event ContractDeactivated(uint contractID);


    struct OptionContract { 
    
        bool active;
        bool exercised;
        ItemType itemType;
        
        address seller;
        address buyer;

        Order order;

        uint256 totalIncome;
        uint256 ethBalance;
        
    }
    struct Order{
        address nftAddr; 
        uint256 nftId;
        uint256 strikePrice; 
        uint256 premium; 
        uint256 duration;
        uint256 expieryDate;
    }

    constructor() {
        s_owner = msg.sender;
        whitelistedAddresses[0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258] = true; //otherdeed
        whitelistedAddresses[0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D] = true; //boredapeyachtclub
        whitelistedAddresses[0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B] = true; //cloneX
        whitelistedAddresses[0x23581767a106ae21c074b2276D25e5C3e136a68b] = true; //proof-moonbirds
        whitelistedAddresses[0x394E3d3044fC89fCDd966D3cb35Ac0B32B0Cda91] = true; //renga
        whitelistedAddresses[0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e] = true; //doodle
        whitelistedAddresses[0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e] = true; //goblintownwtf
        whitelistedAddresses[0x64Ad353BC90A04361c4810Ae7b3701f3bEb48D7e] = true; //renga-black-box
        whitelistedAddresses[0x1A92f7381B9F03921564a437210bB9396471050C] = true; //cool-cats-nft
        whitelistedAddresses[0xd1258DB6Ac08eB0e625B75b371C023dA478E94A9] = true; //digidaigaku
        whitelistedAddresses[0xED5AF388653567Af2F388E6224dC7C4b3241C544] = true; //azuki
    }


    function getInterfaceType(address _nft) public view returns (ItemType) {
        IERC165 _thisNFT = IERC165(_nft);
        if (_thisNFT.supportsInterface(ERC1155InterfaceId)) 
            return ItemType.ERC1155;
        else if (_thisNFT.supportsInterface(ERC721InterfaceId))
            return ItemType.ERC721;
        else 
            return ItemType.OTHER;
    } 
    
    // when nft owner deposit nft and setup the machine, return capsule ID
    function setUpContract(address _assetAddress, uint256 _tokenId, uint256 _strikePrice, uint256 _premium, uint256 _duration) 
        external
        returns (uint256 contractID)
    {   
        // check whitelisted nft
        require(isAddressWhitelisted(_assetAddress) == true, "Asset Address isn't whitelisted");

        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        require(_nftType != ItemType.OTHER, "Asset is not a recognizable type of NFT");


        // deposit nft
        if (_nftType == ItemType.ERC721) {
            IERC721 _thisNFT = IERC721(_assetAddress);
            _thisNFT.transferFrom(tx.origin, address(this), _tokenId);
        } else if (_nftType == ItemType.ERC1155) {
            IERC1155 _thisNFT = IERC1155(_assetAddress);
            _thisNFT.safeTransferFrom(tx.origin, address(this), _tokenId, 1, '');
        }



        // setup capsule info
        uint256 _newContractID = allContracts.length;
        OptionContract memory c; 
        c.seller = tx.origin;
        c.active = true;
        c.itemType = _nftType;
        Order memory order;
        c.order = order;
        c.order.duration = _duration;

        // set it to expired
        c.order.expieryDate = block.timestamp;
        
        c.order.nftAddr = _assetAddress;
        c.order.nftId = _tokenId;
        c.order.strikePrice = _strikePrice;
        c.order.premium = _premium;

        contractIDToHost[tx.origin].push(_newContractID);
        // numberOfContract[tx.origin] = numberOfContract[tx.origin]+1;

        allContracts.push(c);

        emit ContractCreated(_newContractID, tx.origin, _assetAddress, _tokenId);

        return _newContractID;
    }

    function getNumberOfContractPerAddress(address _owner) public view returns (uint256 num){
        return contractIDToHost[_owner].length;
    }

    // generate jackpotNum using blockHash % (odds)
    // function _generateJackpotNum(uint256 odds) internal view returns (uint256 rand) {
    //     return uint256(keccak256(abi.encodePacked(block.difficulty))) % (odds) ;
    // }    

    // player buys capsule partition
    function buyContract(uint256 _contractID) public payable
    {
        require(isContractAvailable(_contractID) == true, "Contract is not available.");
        OptionContract storage c = allContracts[_contractID];

        require(msg.value >= c.order.premium, "Insufficient fund");

        c.buyer = tx.origin;
        c.totalIncome += msg.value;
        c.ethBalance += msg.value;
        // update the expieryDate of the option contract
        c.order.expieryDate = c.order.duration + block.timestamp;

        emit BuyContract(_contractID, tx.origin);
    }

    function modifyContract(uint256 _contractID, uint256 _duration, uint256 _strikePrice, uint256 _premium) public{
        require(isContractAvailable(_contractID) == true, "Contract is not available.");
        OptionContract storage c = allContracts[_contractID];
        c.order.duration = _duration;
        c.order.strikePrice = _strikePrice;
        c.order.premium = _premium;
    }

    function deactivateContract(uint256 _contractID) public{
        require(isContractAvailable(_contractID) == true, "Contract is not available.");
        OptionContract storage c = allContracts[_contractID];
        require (tx.origin == c.seller, "not contract owner.");
        // deactivate
        c.active = false;
        if (c.itemType == ItemType.ERC1155){
            // withdraw ERC1155
            IERC1155 _thisNft = IERC1155(c.order.nftAddr);
            _thisNft.safeTransferFrom(address(this), tx.origin, c.order.nftId, 1, '');
        }
        if (c.itemType == ItemType.ERC721){
            // withdraw ERC721
            IERC721 _thisNft = IERC721(c.order.nftAddr);
            _thisNft.transferFrom(address(this), tx.origin, c.order.nftId);

        }
        if(c.ethBalance > 0){
            uint256 commission = c.ethBalance * contractCommission/1000;
            uint256 withdrawAmt = c.ethBalance - commission;
            (bool success1, ) = (address(c.seller)).call{value: withdrawAmt }("");
            require(success1, "withdraw failed.");
            c.ethBalance  = 0;
            (bool success2, ) = owner().call{value: commission }("");
            require(success2, "withdraw commission failed.");
        }
        finishedcontractIDs.push(_contractID);

        emit ContractDeactivated(_contractID);
    }

    function sellerWithdrawFund(uint256 _contractID) external {
        require(isContractExist(_contractID), "contract does not exist.");
        OptionContract storage c = allContracts[_contractID];
        require(msg.sender == c.seller, "only for seller");
        require(c.ethBalance > 0, "no available fund for withdraw.");

        // transfer fund
        uint256 commission = c.ethBalance * contractCommission/1000;
        uint256 withdrawAmt = c.ethBalance - commission;
        (bool success1, ) = (address(c.seller)).call{value: withdrawAmt}("");
        require(success1, "withdraw failed.");
        c.ethBalance  = 0;
        (bool success2, ) = owner().call{value: commission }("");
        require(success2, "withdraw commission failed.");
    }
    

    function cancelOffer(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, address _buyer, uint256 _effectiveDate, bytes32 _salt,
    bytes memory _signature) public{
        
        bool verified = verify(_buyer, _assetAddress, _strikePrice, _premium, _duration, _effectiveDate, _salt, _signature);
        require(verified == true, "wrong signature!");
        require(_buyer == tx.origin, "this is not your offer!");
        
        allSignatures[_signature] = true;
    }


    function fulfillOrder(address _assetAddress, uint256 _tokenId, uint256 _strikePrice, uint256 _premium, uint256 _duration, address _buyer, uint256 _effectiveDate, bytes32 _salt,
    bytes memory _signature) public{
        //check balance
        require(_effectiveDate > block.timestamp, "offer expired!");


        bool verified = verify(_buyer, _assetAddress, _strikePrice, _premium, _duration, _effectiveDate, _salt, _signature);
        require(verified == true, "wrong signature!");
        require(allSignatures[_signature] != true, "offer no longer available.");

        allSignatures[_signature] = true;
        
        uint256 _contractID = this.setUpContract(_assetAddress,  _tokenId,  _strikePrice,  _premium,  _duration);

        // ERC20 funciton, transfer WETH
        uint256 commission = _premium * contractCommission/1000;
        uint256 withdrawAmt = _premium - commission;
        IERC20 _weth = IERC20(WETH_ADDRESS);
        _weth.transferFrom(_buyer, tx.origin, withdrawAmt);
        _weth.transferFrom(_buyer, address(owner()), commission);


        OptionContract storage c = allContracts[_contractID];
        c.buyer = _buyer;
        c.totalIncome += _premium;
        // update the expieryDate of the option contract
        c.order.expieryDate = c.order.duration + block.timestamp;

        emit BuyContract(_contractID, _buyer);

    }
    

    function exerciseContract(uint256 _contractID) public payable returns(bool){
        if (_contractID < 0 || _contractID >= allContracts.length) 
            return false;
        OptionContract storage c = allContracts[_contractID];
        require (tx.origin == c.buyer, "not contract buyer.");
        require (c.order.expieryDate > block.timestamp, "contract expired");
        require(msg.value >= c.order.strikePrice, "Insufficient fund");
        
        // deavtivate
        c.active = false;
        c.exercised =  true;

        if (c.itemType == ItemType.ERC1155){
            IERC1155 _thisNft = IERC1155(c.order.nftAddr);
            _thisNft.safeTransferFrom(address(this), c.buyer, c.order.nftId, 1, '');
            // withdraw ERC1155
        }
        if (c.itemType == ItemType.ERC721){
            IERC721 _thisNFT = IERC721(c.order.nftAddr);
            _thisNFT.transferFrom(address(this), tx.origin, c.order.nftId);
            // withdraw ERC721
        }

        uint256 commission = (c.ethBalance + msg.value) * contractCommission/1000;
        uint256 withdrawAmt = (c.ethBalance + msg.value) - commission;
        (bool success1, ) = (address(c.seller)).call{value: withdrawAmt}("");
        require(success1, "withdraw failed.");
        c.ethBalance  = 0;
        (bool success2, ) = owner().call{value: commission }("");
        require(success2, "withdraw commission failed.");
        
        finishedcontractIDs.push(_contractID);
        emit ContractExercised(_contractID);
        return true;
    }



    function isContractExist(uint256 _contractId) public view returns (bool) {
        if (_contractId < 0 || _contractId >= allContracts.length) 
            return false;

        return true;
    }


    function isContractAvailable(uint256 _contractId) public view returns (bool) {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = allContracts[_contractId];
        if (c.exercised != true && c.active == true && c.order.expieryDate < block.timestamp)
            return true;

        return false;
    }

    // function getCapsuleJackpotNum(uint _contractId) public view
    //     returns (uint resultNum)
    // {
    //     require(isContractExist(_contractId), "capsule not exist.");
    //     Capsule memory c = allCapsules[_contractId];
    //     return c.jackpotNum;
    // }

    function getContractDetail(uint256 _contractId) public view
    returns(uint256, bool, bool, ItemType, address, address, address, uint256, uint256, uint256, uint256, uint256)
    {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = allContracts[_contractId];
        return (
            // c.contractID,
            _contractId,
            c.active,
            c.exercised,
            c.itemType,

            c.seller,
            c.buyer,

            c.order.nftAddr, 
            c.order.nftId,

            c.order.strikePrice, 
            c.order.premium, 
            c.order.duration,
            c.order.expieryDate
        );
    }
    

    function getContractIncome(uint256 _contractId) public view
    returns(uint256, uint256, uint256)
    {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = allContracts[_contractId];
        return (
            // c.contractID,
            _contractId,
            c.totalIncome,
            c.ethBalance
        );
    }
    
    
    // function getPlayerBalance(address _playerAdr) 
    //     returns (int balance)
    // {
    //     return allPlayerBalances[_playerAdr];
    // }

    // function modifyWinningCommission(uint newPercent) onlyOwner
    // {
    //     winningCommissionPercent = newPercent;
    // }

    // function getActiveCapsuleNum() public view returns (uint256) 
    // {
    //     return allActiveCapsules.length;
    // }

    function getContractNum() public view returns (uint256) 
    {
        return allContracts.length;
    }

    function getFinishedContractNum() public view returns (uint256) 
    {
        return finishedcontractIDs.length;
    }

    function getFinishedContractID(uint256 index) public view returns (uint256) 
    {
        return finishedcontractIDs[index];
    }

    function isAddressWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return whitelistedAddresses[_whitelistedAddress] == true;
    }

    function addAddressesToWhitelist(address[] memory _addressesToWhitelist) public onlyOwner {
        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(whitelistedAddresses[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            whitelistedAddresses[_addressesToWhitelist[index]] = true;
        }        
    }

    function removeAddressesFromWhitelist(address[] memory _addressesToRemove) public onlyOwner {
        for (uint256 index = 0; index < _addressesToRemove.length; index++) {
            require(whitelistedAddresses[_addressesToRemove[index]] == true, "Address isn't whitelisted");
            whitelistedAddresses[_addressesToRemove[index]] = false;
        }
    }

    
    
    // not applying for now
    // function flipOnlyWhitelist() public onlyOwner {
    //     _onlyWhitelisted = !_onlyWhitelisted;
    // }

    function adjustBetFee(uint256 newFee) external onlyOwner {
        betFee = newFee;
    }

    function editContractCommission(uint256 newAmt) external onlyOwner {
        contractCommission = newAmt;
    }



    function kill() external onlyOwner {
        selfdestruct(payable(address(owner())));
    }




    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }


    // code for signature and verification
    function getMessageHash(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _effectiveDate, bytes32 salt)public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_assetAddress, _strikePrice, _premium, _duration, _effectiveDate, salt));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }


    //verify the signed messaged
    function verify(
        address _signer,
        address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _effectiveDate, bytes32 salt,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_assetAddress, _strikePrice, _premium, _duration, _effectiveDate, salt);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }
}


// todo: review and remove all unnecessary comment