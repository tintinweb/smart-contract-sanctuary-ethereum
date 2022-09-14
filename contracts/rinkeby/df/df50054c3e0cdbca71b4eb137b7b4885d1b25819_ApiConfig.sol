/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma solidity ^0.4.24;

contract ApiConfig{
    address public owner;

    address public ethereum_account;
    string public ethereum_account_prikey;
    uint256 public ethereum_number;

    address public ens_fax_domain_owner;
    string public ens_fax_domain_prikey;

    address public user_data_owner;
    string public user_data_prikey;

    struct MediaServer{
      string service_id;
      string service_key;
      string url;
      string nameorip;
      uint port;
    }
    mapping (uint => MediaServer) public licodeServers;
    mapping (uint => MediaServer) public pushNodes;
    mapping (uint => MediaServer) public socketioNodes;
    event savingsEvent(uint indexed _memberId);
    uint public serverCount;
    uint public pushNodeCount;
    uint public socketioNodeCount;

    constructor() public{
      owner = msg.sender;
    }

    function setApiConfig(
        address _ether_account,
        string _ether_prikey,
        uint256 _ether_number,
        address _ens_fax_owner,
        string _ens_fax_prikey,
        address _user_data_owner,
        string _user_data_prikey
    ) public returns(bool success){
        require(owner == msg.sender);

        ethereum_account = _ether_account;
        ethereum_account_prikey = _ether_prikey;
        ethereum_number = _ether_number;

        ens_fax_domain_owner = _ens_fax_owner;
        ens_fax_domain_prikey = _ens_fax_prikey;

        user_data_owner = _user_data_owner;
        user_data_prikey = _user_data_prikey;
        return success;
    }

    function addLicodeServer(string _service_id, string _service_key, string _url, string _domainorip, uint256 _port) public returns(bool success){
      require(msg.sender == owner);
      licodeServers[serverCount] = MediaServer(_service_id,_service_key,_url,_domainorip,_port);
      serverCount++;
      return true;
    }
  function addPushNode(string _service_id, string _service_key, string _url, string _domainorip, uint256 _port) public returns(bool success){
    require(msg.sender == owner);
    pushNodes[pushNodeCount] = MediaServer(_service_id,_service_key,_url,_domainorip,_port);
    pushNodeCount++;
    return true;
  }

  function addSocketioNode(string _service_id, string _service_key, string _url, string _domainorip, uint256 _port) public returns(bool success){
    require(msg.sender == owner);
    socketioNodes[socketioNodeCount] = MediaServer(_service_id,_service_key,_url,_domainorip,_port);
    socketioNodeCount++;
    return true;
  }

  function removeLicodeServer(uint256 num) public returns (bool success){
    require(msg.sender == owner);
    delete licodeServers[num];
    return true;
  }
  function removeSocketioNode(uint256 num) public returns (bool success){
    require(msg.sender == owner);
    delete socketioNodes[num];
    return true;
  }
  function removePushNode(uint num) public returns (bool success){
    require(msg.sender == owner);
    delete pushNodes[num];
    return true;
  }

  function setEtherAccount(address _ether_account, string _ether_prikey, uint256 _ether_number) public returns(bool success){
        require(msg.sender == owner);
        ethereum_account = _ether_account;
        ethereum_account_prikey = _ether_prikey;
        ethereum_number = _ether_number;

        return true;
    }

    function setEnsFaxDomainAccount(address _ens_fax_owner, string _ens_fax_prikey) public returns(bool success){
        require(msg.sender == owner);
        ens_fax_domain_owner = _ens_fax_owner;
        ens_fax_domain_prikey = _ens_fax_prikey;

        return true;
    }

    function setUserDataAccount(address _user_data_owner, string _user_data_prikey) public returns(bool success){
        require(msg.sender == owner);
        user_data_owner = _user_data_owner;
        user_data_prikey = _user_data_prikey;

        return true;
    }
}