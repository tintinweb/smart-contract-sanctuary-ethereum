/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

contract CCC {
    struct member{
        string id;
        bytes32 password;
    }
    // 나중에 본인인증 정보를 byte32로 넣어보고 싶어서 바꿨습니다.
    mapping(bytes32 => member) memberMapping;

    function getHash(string memory _string) private view returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    function join(string memory _id, string memory _password) public returns(bool) {
        memberMapping[getHash(_id)] = member(_id, getHash(_password));
        return true;
    }

    function login(string memory _id, string memory _password) public view returns(bool) {
        if(memberMapping[getHash(_id)].password == getHash(_password)){
            return true;
        } else {
            return false;
        }
    }

    // require도 가능할 것 같아서 주석 남겨놓고 해봤습니다
    function delid(string memory _id, string memory _password) public returns(bool) {
        require(login(_id,_password) == true);
        delete memberMapping[getHash(_id)];
        // if(memberMapping[_id].password == getHash(_password)){
        //     delete memberMapping[_id];
        //     return true;
        // } else {
        //     return false;
        // }
    }
}