// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract RewardClaimSig {
    ERC20 public token;
    ERC721 public nft;

    struct RequestStruct {
        bool isActive;
        bool isClosed;
        bool isSent;
        address createdBy;
        address dealedBy;
        address to;
        uint256 value;
        uint256 index;
    }

    struct ClaimStruct {
        address account;
        uint256 balance;
    }
    
    struct Claimable {
        bool able;
        uint256 balance;
    }

    RequestStruct[] public transferList;
    ClaimStruct[] public claimList;
    
    mapping(address => bool) public owners;
    mapping(address => Claimable) public reward;

    address[] public ownArray;
    address public treasuryWallet;
    address public claimWallet;

    uint256 public transferedAmount;
    uint256 public cancelTransferNumber;
    uint256 public unClaimedBalance;
    uint256 public amountOnClaim = 500 ether;

    bool public outStanding;

    modifier onlyOwners() {
        require(owners[msg.sender]);
        _;
    }

    modifier onlyNFTOwner() {
        require(nft.balanceOf(msg.sender) > 0);
        _;
    }

    function setTokenAddress(address tokenAddress) private onlyOwners {
        token = ERC20(tokenAddress);
    }

    constructor(
        address[] memory _owners,
        address tokenAddress,
        address _nft,
        address _treasury,
        address _claim
    ) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) owners[_owners[i]] = true;
        setTokenAddress(tokenAddress);
        nft = ERC721(_nft);
        treasuryWallet = _treasury;
        claimWallet = _claim;
    }

    // start transfer part
    function newTransferRequest(address to, uint256 value) public onlyOwners {
        RequestStruct memory transferRequest = RequestStruct({
            to: to,
            value: value,
            isClosed: false,
            isSent: false,
            isActive: true,
            index: transferList.length,
            createdBy: msg.sender,
            dealedBy: msg.sender
        });
        
        transferList.push(transferRequest);
    }
    
    function getTransferItem(uint idx) public view returns(RequestStruct memory item) {
        return transferList[idx];
    }
    
    function approveTransferRequest(uint idx) public onlyOwners  {
        require(transferList[idx].isActive);
        sendTransferRequest(idx);
    }

    function approveTransferListRequest(uint[] memory list) public onlyOwners {
        for (uint i = 0; i < list.length; i ++) {
            require(sendTransferRequest(list[i]));
        }
    }
    
    function declineTransferListRequest(uint[] memory list) public onlyOwners {
        for (uint i = 0; i < list.length; i ++) {
            require(declineTransferRequest(list[i]));
        }
    }
    
    function declineTransferRequest(uint idx) public onlyOwners returns(bool) {
        require(transferList[idx].isActive);
        closeTransferRequest(idx, false);
        cancelTransferNumber ++;
        return true;
    }

    function sendTransferRequest(uint idx) private onlyOwners returns(bool) {
        require(transferList[idx].isActive);
        require(transferList[idx].createdBy != msg.sender, "can't approve transaction you created");
        
        token.transferFrom(transferList[idx].createdBy, transferList[idx].to, transferList[idx].value);
        transferedAmount += transferList[idx].value;
        closeTransferRequest(idx, true);
        return true;
    }
    
    function closeTransferRequest(uint idx, bool status) private onlyOwners {
        transferList[idx].dealedBy = msg.sender;
        transferList[idx].isActive = false;
        transferList[idx].isClosed = true;
        transferList[idx].isSent = status;
    }
    // end transfer part
    
    function getTransferedAmount() public onlyOwners view returns (uint256) {
        return transferedAmount;
    }
    
    function getRequestList() public onlyOwners view returns (RequestStruct[] memory list) {
        return transferList;
    }

    function getclaimList() public onlyOwners view returns(ClaimStruct[] memory list) {
        return claimList;
    }
    
    function getLatestTransferRequest() public onlyOwners view returns(RequestStruct memory item, uint256 cancel) {
        RequestStruct memory sendItem;
        if (transferList.length > 0) sendItem = transferList[transferList.length - 1];
        return (sendItem, cancelTransferNumber);
    }

    function claim() external onlyNFTOwner {
        require(reward[msg.sender].able, "account is not able to claim");
        require(reward[msg.sender].balance > 0, "no balance left");

        uint256 amount = amountOnClaim;
        if (reward[msg.sender].balance < amountOnClaim) {
            amount = reward[msg.sender].balance;
            reward[msg.sender].balance = 0;
        }

        else {
            reward[msg.sender].balance -= amountOnClaim;
        }

        unClaimedBalance -= amount;
        token.transferFrom(treasuryWallet, msg.sender, amount);

    }

    function updateClaimList(ClaimStruct[] memory list) external onlyOwners {
        uint256 restBalance = unClaimedBalance;
        for (uint i; i < claimList.length; i ++) {
            reward[claimList[i].account].able = false;
        }
        
        delete claimList;
        for (uint i; i < list.length; i ++) {
            ClaimStruct memory claimItem = list[i];
            claimList[i] = claimItem;
            reward[claimItem.account].able = true;
            reward[claimItem.account].balance += claimItem.balance;
            restBalance += claimItem.balance;
        }

        unClaimedBalance = restBalance;
    }

}