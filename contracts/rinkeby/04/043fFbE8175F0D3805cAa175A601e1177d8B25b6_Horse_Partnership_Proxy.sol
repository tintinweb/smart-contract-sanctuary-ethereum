//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "Proxiable.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;

    function EQMint(address to, uint256 amount_req) external virtual;

    function setApprovalForAll(address operator, bool approved)
        external
        virtual;

    function exists(uint256 horseID) public view virtual returns (bool);

    function mintfract(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual;

    function burnExt(
        address from,
        uint256 tokenID,
        uint256 amount
    ) external virtual;

    function balanceOf(address from, uint256 tokenID)
        external
        virtual
        returns (uint256);
}

abstract contract ContractGlossaryProxy {
    function getAddress(string memory name)
        public
        view
        virtual
        returns (address);
}

contract Horse_Partnership_Proxy is Proxiable {
    address private HorseAddress;
    address private HorseGovAddress;
    uint256 private fractNumber;
    ContractGlossaryProxy Index;

    address public owner;
    bool public initalized = false;
    string public name = "Silks - Horse Partnership";

    function fractionalize(uint256 horseID) external {
        ERC721 HorseContract = ERC721(Index.getAddress("Horse"));
        ERC721 HorseGovContract = ERC721(Index.getAddress("HorseGovernance"));
        ERC721 HorsePartnershipContract = ERC721(
            Index.getAddress("HorsePartnership")
        );
        require(
            HorseContract.ownerOf(horseID) == msg.sender,
            "DOESN'T OWN TOKEN"
        );
        HorseContract.transferFrom(msg.sender, address(this), horseID);
        HorsePartnershipContract.mintfract(
            msg.sender,
            horseID,
            fractNumber,
            ""
        );
        if (!(HorseGovContract.exists(horseID))) {
            HorseGovContract.EQMint(msg.sender, horseID);
        } else if (HorseGovContract.exists(horseID)) {
            HorseGovContract.transferFrom(address(this), msg.sender, horseID);
        }
    }

    function reconstitute(uint256 horseID) external {
        ERC721 HorseContract = ERC721(Index.getAddress("Horse"));
        ERC721 HorseGovContract = ERC721(Index.getAddress("HorseGovernance"));
        ERC721 HorsePartnershipContract = ERC721(
            Index.getAddress("HorsePartnership")
        );
        require(
            HorsePartnershipContract.balanceOf(msg.sender, horseID) ==
                fractNumber,
            "MUST HAVE ALL EQUITY TOKENS OF HORSE"
        );
        require(
            HorseGovContract.ownerOf(horseID) == msg.sender,
            "MUST HAVE HORSE GOVERNANCE TOKEN"
        );
        HorseContract.transferFrom(address(this), msg.sender, horseID);
        HorsePartnershipContract.burnExt(msg.sender, horseID, fractNumber);
        HorseGovContract.transferFrom(msg.sender, address(this), horseID);
    }

    function setFractNumber(uint256 num) public onlyOwner {
        fractNumber = num;
    }

    function initialize() public {
        require(owner == address(0), "Already initalized");
        require(!initalized, "Already initalized");
        owner = msg.sender;
        initalized = true;
        fractNumber = 9;
    }

    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner is allowed to perform this action"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
            ) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                newAddress
            )
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return
            0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}