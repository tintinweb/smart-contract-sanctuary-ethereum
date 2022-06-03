pragma solidity >=0.5.0 <0.6.0;

library AvatarLibrary {

    struct Avatar {
        string name;
    }

    struct AvatarStorage {
        Avatar[] avatars;
        mapping (address => uint) addressToAvatar;
        mapping (address => bool) wasCreated;
    }

    function createAvatar(AvatarStorage storage self, string memory name) internal {
        require(self.wasCreated[msg.sender] == false, 'You already have an avatar.');
        uint id = self.avatars.push(
            Avatar(
                name
            )
        ) - 1;
        self.addressToAvatar[msg.sender] = id;
        self.wasCreated[msg.sender] = true;
    }

    function getAvatarCount(AvatarStorage storage self) public view returns (uint) {
        return self.avatars.length;
    }

    function getAvatarIdByAddress(AvatarStorage storage self, address owner) public view returns(uint) {
        //require (self.wasCreated[owner], 'Not an avatar.');
        return self.addressToAvatar[owner];
    }

    function getAvatarNameById(AvatarStorage storage self, uint id) public view returns (string memory) {
        return self.avatars[id].name;
    }

    function getAvatarNameByAddress(AvatarStorage storage self, address owner) public view returns (string memory) {
        //require (self.wasCreated[owner], 'Not an avatar.');
        uint avatarId = self.addressToAvatar[owner];
        return self.avatars[avatarId].name;
    }

    function hasAvatar(AvatarStorage storage self, address owner) public view returns (bool) {
        return self.wasCreated[owner];
    }
}