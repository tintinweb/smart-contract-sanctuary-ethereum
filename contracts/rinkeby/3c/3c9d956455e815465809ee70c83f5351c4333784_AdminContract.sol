/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// File: contracts/Admin.sol


pragma solidity 0.8.7;

interface IStorage{
    function getServerAddress() external view returns(address);
    function getOwner() external view returns(address);
    function incrementAdminCounter() external;
    function decrementAdminCounter() external;
    function getAdminCounter() external returns(uint);
    function setAdminId(address _address, uint _adminId) external;
    function getAdminId(address _address) external returns(uint);
    function setAdmin(uint _adminId, address _address) external;
    function getAdmin(uint _adminId) external returns(address);
    function getMaxAdmins() external returns(uint);
    function getEarnings(address _address) external view returns(uint);
    function setEarnings(address _address, uint _approvedAmt) external;
    function withdrawUserEarnings(address _address) external;
}

interface IlandBaronTokenContract{
    function balanceOf(address owner) external view returns (uint256);
}

contract AdminContract{
    //24 HRS = 86400 SECS
    //Test variables
    // uint contractBalance = 100000000000000000000
    // uint liqPool = (contractBalance / 100) * 80
    // uint holdersCount = 1253
    /////////////////////
    address landBaronTokenContractAddress;
    address StorageContract;

    constructor(address _StorageContract){
        StorageContract = _StorageContract;
    }

    function setTokenContract(address _tokenContractAddress) public{
        require(IStorage(StorageContract).getOwner() == msg.sender, "Only the owner can set the token contract..");
        landBaronTokenContractAddress = _tokenContractAddress;
    }

    function addAdminRole(address _address) public {
        require(IStorage(StorageContract).getAdminId(_address) < 1, "The provided address is already assigned to the admin role");
        if(IStorage(StorageContract).getAdminCounter() < IStorage(StorageContract).getMaxAdmins()){
            IStorage(StorageContract).incrementAdminCounter();
            IStorage(StorageContract).setAdminId(_address, IStorage(StorageContract).getAdminCounter());
            IStorage(StorageContract).setAdmin(IStorage(StorageContract).getAdminCounter(), _address);
        }else{
            for(uint i = 1; i <= IStorage(StorageContract).getMaxAdmins(); i++){
                if(IStorage(StorageContract).getAdmin(i) == 0x0000000000000000000000000000000000000000){
                    IStorage(StorageContract).setAdminId(_address, i);
                    IStorage(StorageContract).setAdmin(i, _address);
                    return;
                }
            }
            revert("No more admin slots available");
        }
    }

    function removeAdminRole(address _address) public {
        require(IStorage(StorageContract).getAdminId(_address) > 0, "The provided address is NOT assigned to the admin role");
        IStorage(StorageContract).setAdmin(IStorage(StorageContract).getAdminId(_address), 0x0000000000000000000000000000000000000000);
        IStorage(StorageContract).setAdminId(_address, 0);
    }

    function userWithdraw() public {
        require(approved(msg.sender), "You are not approved for a withdraw at this time...");
        IStorage(StorageContract).withdrawUserEarnings(msg.sender);
    }

    function approveUserWithdraw(address _address, uint _approvedAmt) public {
        require(msg.sender == IStorage(StorageContract).getServerAddress());
        IStorage(StorageContract).setEarnings(_address, _approvedAmt);
    }

    function approved(address _address) public view returns(bool){
        require(IlandBaronTokenContract(landBaronTokenContractAddress).balanceOf(_address) > 0);
        if(IStorage(StorageContract).getEarnings(msg.sender) > 0){
            return true;
        }else{
            return false;
        }
    }

    // function dailyrefresh() public 




    // function getPotentialEarnings(address _address) public view returns(uint){
    //     uint earnings = liqPool / holdersCount;
    //     return earnings;
    // }

    // function holderWithdraw() public onlyHolder{

    // }
}