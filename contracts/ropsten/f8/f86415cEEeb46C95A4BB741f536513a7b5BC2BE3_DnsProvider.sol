/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.8.7;
/** @title Free decentralized DNS provider for Onion. */
contract DnsProvider{
    //-->Variables
    address payable public owner;
    uint constant public handlingCost =  1800000000000000;
    mapping(address=>string[]) private URLsByOwners;
    mapping(string=>string[]) private nameOnions;
    mapping(string => bool) public nameExist;
    mapping(address=>uint) private userBalance;
    uint public totalSupply;
    bool private lockBalances;
    //-->End
    //-->Events
    event Deposit(address sender, uint amount, uint balance);
    event WithdrawBalance( address user,uint amount, uint totalSupply);
    //-->End
    constructor()payable{
        owner = payable(msg.sender);
    }
    fallback() external payable {
       require(msg.data.length == 0); 
    }
    /** @dev Use this method to deposit money in the contract.*/
    function deposit() payable external {
        require(!lockBalances);
        lockBalances = true;
            userBalance[msg.sender]+=msg.value;
            totalSupply += msg.value;
        lockBalances = false;
        assert(address(this).balance >= totalSupply);
        emit Deposit(msg.sender, msg.value, userBalance[msg.sender]);
    }
    /** @dev The user can use this method to withdraw the remaining money.*/
    function withdrawBalance() public {
        require(!lockBalances);
        lockBalances = true;
            uint amountToWithdraw = userBalance[msg.sender];
            userBalance[msg.sender] = 0;
            totalSupply -= amountToWithdraw;
            bool success = payable(msg.sender).send(amountToWithdraw);
        lockBalances = false;
        require(success);
        emit WithdrawBalance( msg.sender, amountToWithdraw, totalSupply);
    }
    /** @dev Obtain the balance that the contract has.
      * @return contract balance.
      */
    function getBalance()external view returns(uint){
        return address(this).balance;
    }
    /** @dev The user can arrogate a DNS name that no one else owns.
      * @param _urlName new DNS name.
      */
    function setURL(string memory _urlName)external{
        require(!nameExist[_urlName]);
        require(runThePayment());
        URLsByOwners[msg.sender].push(_urlName);
        nameExist[_urlName] = true;
    }
    /** @dev The user can obtain the DNS names of his property.
      * @return string[] DNS name listing.
      */
    function getURLs() view external returns(string[] memory){
        return URLsByOwners[msg.sender];
    }
    /** @dev Delete a DNS name.
      * @param _urlName Name DNS.
      */
    function deleteURLs(string memory _urlName)external{
        require(nameExist[_urlName]);
        string[] memory urlNames = URLsByOwners[msg.sender];
        for(uint i=0; i<urlNames.length; i++){
            if(memcmp(bytes(urlNames[i]), bytes(_urlName))){
                delete URLsByOwners[msg.sender][i];
                delete nameOnions[_urlName];
                delete nameExist[_urlName];
            }
        }
     }
     /** @dev Transfer ownership of a DNS name to another user.
      * @param _to User that receives the DNS name.
      * @param _urlName name DNS.
      */
     function transferURLs(address _to, string memory _urlName)external{
        require(nameExist[_urlName]);
        string[] memory urlNames = URLsByOwners[msg.sender];
        for(uint i=0; i<urlNames.length; i++){
            if(memcmp(bytes(urlNames[i]), bytes(_urlName))){
                delete nameOnions[_urlName];
                delete URLsByOwners[msg.sender][i];
                URLsByOwners[_to].push(_urlName);
            }
        }
     }
     /** @dev Associate a list of onion addresses to a DNS name.
      * @param _urlName name DNS.
      * @param _onions string[] Onions to associate to _urlName.
      */
    function setOnions( string memory _urlName, string[] memory _onions)external{
        require(userBalance[msg.sender]>=handlingCost);
        require(nameExist[_urlName]);
        string[] memory urlNames = URLsByOwners[msg.sender];
        for(uint i=0; i<urlNames.length; i++){
            if(memcmp(bytes(urlNames[i]), bytes(_urlName))){
                require(runThePayment());
                nameOnions[urlNames[i]]=_onions;
            }
        }
    }
    /** @dev Obtain onion addresses associated with a DNS name.
      * @param _urlName name DNS.
      * @return string[] Onion addresses associated with _urlName.
      */
    function getOnions(string memory _urlName)external view returns(string[] memory){
        string[] memory onions = nameOnions[_urlName];
        return onions;
    }
    function runThePayment() internal returns(bool){
         require(!lockBalances);
         lockBalances = true;
            require(userBalance[msg.sender]>=handlingCost);
            userBalance[msg.sender]-=handlingCost;
            totalSupply -= handlingCost;
            bool success = owner.send(handlingCost);
         lockBalances = false;
         return success;
    }
    function withdrawSurplus()public onlyOwner{
        require(!lockBalances);
        lockBalances = true;
            uint amountToWithdraw = address(this).balance - totalSupply;
            bool success = owner.send(amountToWithdraw);
        lockBalances = false;
        require(success);
        emit WithdrawBalance( msg.sender, amountToWithdraw, address(this).balance);
    }
    modifier onlyOwner(){
            require(msg.sender == owner);
            _;
    }
    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
}