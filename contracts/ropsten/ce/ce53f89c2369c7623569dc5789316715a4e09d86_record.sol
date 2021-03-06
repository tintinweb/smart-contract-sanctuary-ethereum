pragma solidity ^0.4.18;

contract record {
    
    mapping (bytes32 => mapping (bytes32 => string)) public records;
    mapping (bytes32 => mapping (bytes32 => bool)) public sigs;
    mapping (bytes32 => address) public passwords;
    // bytes32 public temp1;
    // bytes32 public temp2;
    // address public a1;

    function recoverAddr(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, msgHash);
        return ecrecover(prefixedHash, v, r, s);
    }

    // modifier rightSignature(bytes32  _username, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) {
    //     require(ecrecover(msgHash, v, r, s) == passwords[_username]);
    //     _;
    // }
    
    modifier isEmpty(bytes32 _username, bytes32 _name) {
        require(sigs[_username][_name] == false);
        _;        
    }
    
    function register(bytes32 _username, address _passwd) public returns (bool) {
        require(passwords[_username] == address(0));
        passwords[_username] = _passwd;

    }

    function changePasswd(bytes32 _user, address _new, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 hash = keccak256(_new);
        require(recoverAddr(hash, _v, _r, _s) == passwords[_user]);
        passwords[_user] = _new;
    }
    
    function writePublicRecord(bytes32 _username, bytes32 _name, string _data, uint8 _v, bytes32 _r, bytes32 _s)
    public {
        require(recoverAddr(_name, _v, _r, _s) == passwords[_username]);
        require(sigs[_username][_name] == false);
        records[_username][_name] = _data;
        sigs[_username][_name] = true;
    }
    
    function readPublicRecord(bytes32 _username, bytes32 _name) public constant returns (string) {
        return records[_username][_name];
    }

}