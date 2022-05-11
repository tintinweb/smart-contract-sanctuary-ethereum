/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2017-03-15
*/

pragma solidity ^0.4.3;

contract Avatars {
    
    uint avatarsCount = 0;

    struct Avatar {
        uint id;
        
        /**
         * Avatar's owner.
         */ 
        address owner;
        
        /**
         * First byte is gender, 1 / 0 for male / female. 
         * Then every byte describe choosen avatar part. 
         * The order is : backs, clothes, ears, eyebrows, eyesfront, eyesiris, faceshape, glasses, hair, mouth, nose, beard, mustache. 
         */ 
        bytes32 shapes;
        
        /**
         * Each 3 bytes describe color for 5 first shapes.
         */
        bytes32 colorsPrimary;
        
        /**
         * Each 3 bytes describe color for 8 last shapes.
         */
        bytes32 colorsSecondary;
        
        /**
         * Each byte describes up/down position for every shape. 
         * High nibble depicts the sign of number, 1 - up, 0 - down.
         * Low nibble shows number of steps to move the shape in selected direction.
         * 
         */
        bytes32 positions;
    }
    
    mapping(bytes32 => Avatar) avatars;
    
    /**
     * Stores an avatar on the blockchain.
     * Throws if avatar with such shapes combination is already exists.
     * 
     * @param shapes - hex string, depicts gender and combinations of shapes.
     * @param colorsPrimary - hex string, colors of the first 5 shapes.
     * @param colorsSecondary - hex string, colors of the last 8 shapes.
     * @param positions - hex string, up/down positions of all shapes
     * 
     * @return Hash of the avatar.
     */
    function register(string shapes, string colorsPrimary, string colorsSecondary, string positions) returns (bytes32 avatarHash) {
        bytes32 shapesBytes = strToBytes(shapes);
        bytes32 colorsPrimaryBytes = strToBytes(colorsPrimary);
        bytes32 colorsSecondaryBytes = strToBytes(colorsSecondary);
        bytes32 positionsBytes = strToBytes(positions);

        // unique by shapes composition
        bytes32 hash = sha3(shapes);

        Avatar memory existingAvatar = avatars[hash];
        if (existingAvatar.id != 0)
            throw;
        
        Avatar memory avatar = Avatar(++avatarsCount, msg.sender, 
            shapesBytes,
            colorsPrimaryBytes,
            colorsSecondaryBytes,
            positionsBytes);

        avatars[hash] = avatar;
        return hash;
    }
    
    /**
     * Returns an avatar by it's hash.
     * Throws if avatar is not exists.
     */ 
    function get(bytes32 avatarHash) constant returns (bytes32 shapes, bytes32 colorsPrimary, bytes32 colorsSecondary, bytes32 positions) {
        Avatar memory avatar = getAvatar(avatarHash);
        
        shapes = avatar.shapes;
        colorsPrimary = avatar.colorsPrimary;
        colorsSecondary = avatar.colorsSecondary;
        positions = avatar.positions;
    }
    
    /**
     * Returns an avatar owner address by avatar's hash.
     * Throws if avatar is not exists.
     */ 
    function getOwner(bytes32 avatarHash) constant returns (address) {
        Avatar memory avatar = getAvatar(avatarHash);
        return avatar.owner;
    }
    
        
    /**
     * Returns if avatar of the given hash exists.
     */ 
    function isExists(bytes32 avatarHash) constant returns (bool) {
        Avatar memory avatar = avatars[avatarHash];
        if (avatar.id == 0)
            return false;
            
        return true;
    }
    
    /**
     * Returns an avatar by it's hash.
     * Throws if avatar is not exists.
     */ 
    function getAvatar(bytes32 avatarHash) private constant returns (Avatar) {
        Avatar memory avatar = avatars[avatarHash];
        if (avatar.id == 0)
           throw;
           
        return avatar;
    }
    
    /**
     * @dev Low level function.
     * Converts string to bytes32 array.
     * Throws if string length is more than 32 bytes
     * 
     * @param str string
     * @return bytes32 representation of str
     */
    function strToBytes(string str) constant private returns (bytes32 ret) {
        // var g = bytes(str).length;
        // if (bytes(str).length > 32) throw;
        
        assembly {
            ret := mload(add(str, 32))
        }
    } 
}