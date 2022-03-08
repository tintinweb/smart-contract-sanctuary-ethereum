/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface Vizmesh {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract VizmeshConfigMainnet {
    address public vizmeshSmartContractAddress;
    address public ownerAddress;
    mapping (uint256 => bool) public isPauseds;
    mapping (uint256 => ethNft) public ethNfts;
    mapping (uint256 => otherNft) public otherNfts;
    mapping (uint256 => coord) private coords;

    event logSetEthNft(address _from, uint256 _frmId, address _nftSmartContractAddress, uint256 _nftTokenId);
    event logSetOtherNft(address _from, uint256 _frmId, string _delimitedText);
    event logSetIsPaused(uint256 _frmId, bool _isPaused);
    event logSetCoord(address _from, uint256 _frmId, int32 _x, int32 _y);

    constructor () {
        ownerAddress = msg.sender;
        vizmeshSmartContractAddress = 0xFDf676eF9A5A74F8279Cd5fC70B8c1b9116b05CD;
    }

    struct ethNft {
        address nftSmartContractAddress;
        uint256 nftTokenId;
    }

    struct otherNft {
        string delimitedText;
    }

    struct coord {
        int256 x;
        int256 y;
    }

    function setVizmeshSmartContractAddress(address _vizmeshSmartContractAddress)
        public
    {
        require(isOwnerOfSmartContract(), "Must be smart contract owner");
        vizmeshSmartContractAddress = _vizmeshSmartContractAddress;
    }

    function setOwnerOfSmartContract(address _ownerAddress)
        public
    {
        require(isOwnerOfSmartContract(), "Must be smart contract owner");
        ownerAddress = _ownerAddress;
    }

    function isOwnerOfSmartContract()
        public
        view
        returns(bool)
    {
        return msg.sender == ownerAddress;
    }

    function isOwnerOfFrm(uint256 _frmId)
        public
        view
        returns(bool)
    {
        return Vizmesh(vizmeshSmartContractAddress).balanceOf(msg.sender, _frmId) == 1;
    }

    function setIsPaused(uint256 _frmId, bool _isPaused)
        public
    {
        require(isOwnerOfSmartContract(), "Must be smart contract owner");
        isPauseds[_frmId] = _isPaused;
        emit logSetIsPaused(_frmId, _isPaused);
    }

    function setCoord(uint256 _frmId, int32 _x, int32 _y)
        public
    {
        require(isPauseds[_frmId] == false, "FRM must not be paused");
        require(isOwnerOfFrm(_frmId) || isOwnerOfSmartContract(), "Must be FRM owner or smart contract owner to update FRM coordinates.");
        coords[_frmId] = coord(_x, _y);
        emit logSetCoord(msg.sender, _frmId, _x, _y);
    }

    function setEthNft(uint256 _frmId, address _nftSmartContractAddress, uint256 _nftTokenId)
        public
    {
        require(isPauseds[_frmId] == false, "FRM must not be paused");
        require(isOwnerOfFrm(_frmId) || isOwnerOfSmartContract(), "Must be FRM owner or smart contract owner to update FRM NFT.");
        ethNfts[_frmId] = ethNft(_nftSmartContractAddress, _nftTokenId);
        emit logSetEthNft(msg.sender, _frmId, _nftSmartContractAddress, _nftTokenId);
    }

    function setOtherNft(uint256 _frmId, string memory _delimitedText)
        public
    {
        require(isPauseds[_frmId] == false, "FRM must not be paused");
        require(isOwnerOfFrm(_frmId) || isOwnerOfSmartContract(), "Must FRM owner or smart contract owner to update FRM NFT.");
        otherNfts[_frmId] = otherNft(_delimitedText);
        emit logSetOtherNft(msg.sender, _frmId, _delimitedText);
    }

    function getCoord(uint256 _frmId)
        public
        view
        returns(coord memory)
    {
        if(coords[_frmId].x == 0){
            return getDefaultCoord(_frmId);
        }
        else {
            return coords[_frmId];
        }
    }

    function getDefaultCoord(uint256 _frmId)
        public
        pure
        returns(coord memory)
    {
        coord memory c = coord(0, 0);
        int256 i;
        int256 x;
        int256 y;
        for(i = 0; i < 255; i += 1) {
            if(int256(_frmId) > (i * 2) * (i * 2)) {
                continue;
            }
            else {
                int256 thickness = i - 1;
                int256 turn_length = thickness * 2 + 1;
                int256 half_turn_length = thickness + 1;

                int256 j;
                int256 remainder = int256(_frmId) - (thickness * 2) * (thickness * 2);

                //Start at 12 o'clock
                x = 1;
                y = thickness + 1;
                for(j=1; j < remainder; j++) {
                    if(j < half_turn_length) {
                        x += 1;
                    }
                    else if(j < half_turn_length + turn_length ) {
                        y -= 1;
                        if (y == 0) {
                            y -= 1;
                        }
                    }
                    else if(j < half_turn_length + turn_length + turn_length) {
                        x -= 1;
                        if (x == 0) {
                            x -= 1;
                        }
                    }
                    else if(j < half_turn_length + turn_length + turn_length + turn_length) {
                        y += 1;
                        if (y == 0) {
                            y += 1;
                        }
                    }
                    else {
                        x += 1;
                    }
                }

                c = coord(x, y);
                break;
            }
        }
        return c;
    }
}