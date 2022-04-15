//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";

import "./registrant.sol";
import "./metadata.sol";
import "./resolver.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract SubdomainController is Ownable, IERC721, ERC165, IERC721Metadata{

    iRegistrant Registrant;
    iMetadata MetadataProvider;
    iResolver Resolver;

    constructor () {
        Registrant = new Registrant_v1();
        MetadataProvider = new Metadata_v1();
        Resolver = new Resolver_v1();

        emit Transfer(msg.sender, address(0), 1);
    }


    function setResolver(address _addr) public onlyOwner {
        Resolver = iResolver(_addr);
    }

    function setRegistrant(address _addr) public onlyOwner {
        Registrant = iRegistrant(_addr);
    }

    function setMetadata(address _addr) public onlyOwner {
        MetadataProvider = iMetadata(_addr);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {

    }

    function tokenURI(uint256 tokenId) external view returns (string memory)
    {
        return MetadataProvider.metadata("testing");
    }

    function symbol() external view returns (string memory){
        return "";
    }

    function name() external view returns (string memory){
        return "";
    }

    function setApprovalForAll(address operator, bool _approved) external{
        require(false, "cannot be transferred");
    }

    function getApproved(uint256 tokenId) external view returns (address operator){
        require(false, "cannot be transferred");
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool){
        return false;
    }

    function approve(address to, uint256 tokenId) external{
        require(false, "cannot be transferred");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public {

    }

    function ownerOf(uint256 tokenId) public view returns (address _owner) {
        return address(0);
    }

    function balanceOf(address owner) external view returns (uint256 balance){
        return 0;
    }

 

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface iResolver {

}

interface iMapper {

}

interface iRegistrant {

}

interface iMetadata {
    
    function metadata(string calldata _name) external view returns(string memory);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Registrant_v1 is iRegistrant {

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metadata_v1 is iMetadata {

string image = "PD94bWwgdmVyc2lvbj0iMS4wIiBzdGFuZGFsb25lPSJubyI/Pgo8IURPQ1RZUEUgc3ZnIFBVQkxJQyAiLS8vVzNDLy9EVEQgU1ZHIDIwMDEwOTA0Ly9FTiIKICJodHRwOi8vd3d3LnczLm9yZy9UUi8yMDAxL1JFQy1TVkctMjAwMTA5MDQvRFREL3N2ZzEwLmR0ZCI+CjxzdmcgdmVyc2lvbj0iMS4wIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciCiB3aWR0aD0iMjI1LjAwMDAwMHB0IiBoZWlnaHQ9IjIyNS4wMDAwMDBwdCIgdmlld0JveD0iMCAwIDIyNS4wMDAwMDAgMjI1LjAwMDAwMCIKIHByZXNlcnZlQXNwZWN0UmF0aW89InhNaWRZTWlkIG1lZXQiPgoKPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMC4wMDAwMDAsMjI1LjAwMDAwMCkgc2NhbGUoMC4xMDAwMDAsLTAuMTAwMDAwKSIKZmlsbD0iIzAwMDAwMCIgc3Ryb2tlPSJub25lIj4KPHBhdGggZD0iTTEwNzggMjIyMyBjMTIgLTIgMzIgLTIgNDUgMCAxMiAyIDIgNCAtMjMgNCAtMjUgMCAtMzUgLTIgLTIyIC00eiIvPgo8cGF0aCBkPSJNOTczIDIyMTMgYzE1IC0yIDM3IC0yIDUwIDAgMTIgMiAwIDQgLTI4IDQgLTI3IDAgLTM4IC0yIC0yMiAtNHoiLz4KPHBhdGggZD0iTTEyMjAgMjIxMCBjMTgxIC0yMyAzODMgLTEwNSA1MjEgLTIwOSAyMjggLTE3MyAzNzggLTQzNCA0MTggLTcyNgpsMTAgLTcwIC00IDcwIGMtMTIgMTg2IC0xMDYgNDA0IC0yNDcgNTcyIC0xNzEgMjA1IC00NTQgMzU0IC02OTggMzY4IGwtNzUgNAo3NSAtOXoiLz4KPHBhdGggZD0iTTgyMyAyMTkwIGMtMjIxIC01OCAtNDM4IC0yMDIgLTU3NiAtMzgyIC0xNDQgLTE4OSAtMjE1IC0zOTEgLTIyMgotNjMzIGwtNCAtMTIwIDkgMTIwIGMyMSAyOTAgMTEwIDUwOCAyODQgNjkyIDE2MyAxNzMgMzM2IDI3NSA1NTAgMzIzIDQ0IDEwCjcwIDE4IDU2IDE5IC0xNCAwIC01NyAtOSAtOTcgLTE5eiIvPgo8cGF0aCBkPSJNMTAyMCAyMTk0IGMtMTQgLTIgLTU4IC05IC05OCAtMTUgLTIxNCAtMzEgLTQxNSAtMTQwIC01ODAgLTMxNAotMTkwIC0xOTkgLTI4NCAtNDM3IC0yODQgLTcxNSAwIC0yNzggOTQgLTUxNiAyODQgLTcxNSAyNzMgLTI4OCA2NTAgLTM5NQoxMDMzIC0yOTQgMjkxIDc2IDU0MyAyOTAgNjc0IDU3MSAyNDQgNTIzIDE2IDExNDEgLTUxMiAxMzg4IC0xNTQgNzIgLTM4MiAxMTMKLTUxNyA5NHogbTcwMiAtNDgwIGMtMiAtMTIgNiAtMzcgMTYgLTU1IDExIC0xOSAyNSAtNTEgMzIgLTcxIDggLTI3IDI2IC00OAo2MyAtNzQgNzEgLTUxIDEwNyAtODUgMTA3IC0xMDEgMCAtOCAxMiAtMjUgMjcgLTM4IDI3IC0yMyAyOCAtMjMgOSAtNDQgLTE0Ci0xNiAtMzEgLTIxIC02NyAtMjEgLTQ3IDAgLTQ4IC0xIC01OCAtMzcgLTYgLTIxIC0xMSAtNTAgLTExIC02NCAwIC0xOSAtMjQKLTQ5IC05NCAtMTE4IGwtOTUgLTkyIC0zMiAxNiBjLTI2IDE0IC0zMyAxNCAtNDAgNCAtNSAtOCAtMiAtMjAgNyAtMzAgNyAtOAoxNCAtMjMgMTQgLTMyIDAgLTE4IC00MiAtMzMgLTU5IC0yMiAtMTMgNyAtMTMgMSAtMTUgLTExNyAtMSAtOTIgLTcgLTEwOCAtMzQKLTkyIC0xMyA5IC0xOCAyOSAtMjAgOTkgLTIgNjkgLTcgOTMgLTIyIDExMyAtMTUgMTggLTIwIDQwIC0yMCA4MSBsMCA1NiAtMzAKLTUyIGMtMzEgLTU0IC03MCAtNzcgLTkyIC01NSAtMTUgMTUgLTIgNDIgMjAgNDIgMTIgMCAzNSAyNiA2NiA3NSA0MyA2OCA4OQoxMTUgMTEzIDExNSA1IDAgMTYgLTE0IDI0IC0zMiA5IC0yMCAzMSAtNDEgNjEgLTU3IGw0NyAtMjYgNjEgNjAgYzMzIDMzIDYwCjYzIDYwIDY3IDAgMTggLTQ4IDYgLTcwIC0xNyAtMTIgLTEzIC0yNyAtMjIgLTMyIC0xOSAtNCAzIC0yMiAtNiAtMzkgLTIwIC0xNwotMTQgLTM1IC0yNiAtNDAgLTI2IC0xOSAwIC03IDIzIDM5IDc4IDI2IDMxIDU1IDY2IDYyIDc2IDE0IDE4IDE0IDE5IC0xMCA2Ci0xNCAtNyAtNTEgLTMwIC04MiAtNTEgLTg3IC01OSAtODYgLTMwIDIgNTQgbDczIDY5IC0yNiAyNiAtMjYgMjUgLTM4IC0yNQpjLTIxIC0xNCAtNzggLTYwIC0xMjggLTEwMiAtNDkgLTQyIC05NSAtNzYgLTEwMiAtNzYgLTM2IDAgOCA1MCAxMjIgMTQwIDE0NwoxMTQgMjA4IDE5MCAxNTUgMTkwIC0xMiAwIC0yNiAtMTIgLTM1IC0zMCAtOSAtMTYgLTIwIC0zMCAtMjUgLTMwIC0xNiAwIC0xMQozMCA5IDU4IDEwIDE1IDI0IDM4IDMxIDUxIDExIDIyIDggMjEgLTM0IC0xMCAtMTA3IC03OSAtMTM5IC05OSAtMTQ4IC05MyAtMTEKNyAtMjQgLTggLTg0IC0xMDAgLTM1IC01MiAtNDggLTY2IC01NyAtNTcgLTE4IDE4IDMyIDEwNCAxMjIgMjA3IDk0IDEwOCAxNDUKMTU0IDE3MSAxNTQgMzIgMCAyMyAtMjUgLTE4IC01MyAtNTAgLTM1IC0xMjYgLTExNCAtOTMgLTk3IDEzIDcgNDIgMjkgNjUgNDkKMjMgMjAgNTMgNDUgNjkgNTQgMjMgMTUgMjYgMjEgMTcgMzcgLTkgMTcgLTYgMjMgMjIgNDAgNDQgMjcgOTQgMjQgOTAgLTZ6Cm0tNTczIC0zMTMgYy0xIC0xNCA0IC01MCAxMCAtODAgOSAtNDUgOSAtNTggLTQgLTc4IC0yOSAtNDQgLTU5IC0xNiAtNTMgNTIgMgoyNSAwIDQ1IC0zIDQ1IC0xOSAwIC01OSAtNDUgLTU5IC02NiAwIC0xNCAtNSAtMzQgLTEwIC00NSAtMTIgLTIxIC0xIC0yNiAxOAotNyAxOSAxOSAyNyAtMSAxMiAtMjcgLTIwIC0zMiAtMTQwIC0xNTUgLTE1MiAtMTU1IC0xMSAwIC0yIDE3IDI1IDQ4IDExIDEyCjE2IDIyIDEwIDIyIC02IDAgLTE4IC0xMSAtMjcgLTI1IC0xNyAtMjUgLTM2IC0zMyAtMzYgLTE1IDAgNiAzNiA2OCA4MCAxMzcKNDQgNzAgNzggMTI5IDc1IDEzMSAtMTAgMTAgLTc0IC00MSAtODUgLTY4IC03IC0xNiAtMTggLTM1IC0yNiAtNDEgLTExIC05Ci0xNCAtNyAtMTQgMTIgLTEgMjQgLTEgMjQgLTI2IC02IC0xNCAtMTYgLTYxIC03NiAtMTA1IC0xMzIgLTcxIC05MSAtMTA5Ci0xMjQgLTEwOSAtOTMgMCAxOCAxMDMgMjMwIDExMSAyMzAgMTQgMCAxMCAtMzggLTcgLTczIC0xNCAtMjkgLTExIC0yNyAyNCAxMwozNiA0MSAzOCA0NiAyMSA1MiAtMjIgOSAtMjUgMzYgLTUgNjMgMTUgMjEgNDYgMTQgNDYgLTEwIDAgLTE5IDE0IC0xOSAzMCAwIDcKOSAxOSAxNCAyNiAxMSA3IC0zIDE4IDIgMjYgMTEgNyA5IDUxIDQ1IDk4IDc5IDkwIDY2IDExMSA2OSAxMDkgMTV6IG0xMTEKLTEwMCBjMCAtNDIgLTE4OSAtMjE0IC0yNTcgLTIzNSAtMjkgLTkgLTM5IDExIC0xNiAzNiAzMSAzNSA5MSA3OSAxMTQgODMgMjkKNiA4MiA0OCAxMjEgOTUgMTcgMjIgMzMgNDAgMzUgNDAgMiAwIDMgLTkgMyAtMTl6IG0yMCAtNTIgYy0zMCAtMjcgLTU4IC00OQotNjIgLTQ5IC0xNyAwIC02IDE3IDQyIDY5IDQwIDQ0IDUzIDUyIDYzIDQyIDEwIC0xMCAxIC0yMyAtNDMgLTYyeiBtLTYzNCAtMjYKYzE5IC0yOSAzOSAtNTMgNDUgLTUzIDYgMCA5IC0xNCA3IC0zMiAtMiAtMjUgLTEwIC0zNiAtMzEgLTQ2IC0zMCAtMTUgLTcwCi03MCAtNjAgLTg0IDMgLTUgMTMgLTIgMjQgOCAxNyAxNiAxOSAxNiAyNSAwIDEzIC0zNCAtMTQwIC0xOTcgLTE3NCAtMTg1IC02CjIgMTQgNDggNDUgMTAyIDM3IDY1IDU3IDExMyA2MSAxNDQgMyAzMyAyIDQ0IC03IDM5IC02IC00IC0xMSAtMTMgLTExIC0yMSAwCi0yMCAtNDEgLTEyNyAtNDYgLTEyMiAtMyAyIDIgNDQgMTEgOTIgMjEgMTIyIDE5IDEzMCAtMTYgNTAgLTM3IC04OCAtNTcgLTExNQotNjggLTk3IC02IDEwIC0yMSAtNSAtNTQgLTUwIC0yNSAtMzUgLTUyIC03MCAtNjEgLTc3IC0xNCAtMTIgLTE2IC0xMCAtMTYgOAowIDE4IC0zIDIwIC0xOSAxMSAtMjkgLTE1IC02NyAtMTIgLTgyIDYgLTExIDE0IC0xMCAxOCA2IDMwIDIyIDE2IDgwIDM0IDExMgozNCAyNiAwIDMyIDYgODQgODggMjIgMzQgNDYgNjIgNTIgNjIgNyAwIDIzIDIwIDM2IDQ1IDEzIDI1IDI5IDQ0IDM2IDQxIDcgLTIKMTYgMTUgMjMgNDEgMTEgMzkgMTQgNDMgMjggMzIgOSAtNyAzMSAtMzcgNTAgLTY2eiBtNzE0IC01MyBjMCAtMTQgLTU1IC00MAotODYgLTQwIC0yMyAwIC0yNSAyIC0xMyAxNiAyNCAyOSA5OSA0NyA5OSAyNHogbS01MTQgLTk1IGMtNiAtMjggLTQgLTM1IDkKLTM1IDggMCAxNSAtNyAxNSAtMTUgMCAtMjEgLTgwIC05NCAtOTYgLTg4IC0yMiA4IC0xMzggLTg0IC0xNDQgLTExNCAtNyAtMzYKLTk3IC05NSAtMTExIC03MiAtMjIgMzYgLTEwIDU2IDY4IDEwOSAxMDEgNjkgMjEzIDE1OCAyMTMgMTcxIDAgNSA3IDI1IDE0IDQ0CjIwIDQ3IDQwIDQ2IDMyIDB6IG0zMTEgMjMgYzI0IC0zMCA5MiAtMjAzIDg0IC0yMTEgLTEyIC0xMiAtNzcgNzEgLTExNiAxNDYKLTI2IDQ5IC0yOCA1OSAtMTUgNjcgMjAgMTMgMzYgMTIgNDcgLTJ6IG0tNzAgLTY4IGMtMTYgLTQyIC0xMjIgLTEyNSAtMTU2Ci0xMjIgLTE4IDEgLTQ1IC0xMyAtODYgLTQ2IC03MSAtNTcgLTEwNSAtNzggLTEwNSAtNjIgMCAyNCAxODQgMTY1IDIyOSAxNzUKMTUgMyA0NyAyNiA3MSA1MCA0OCA0OSA2NCA1MSA0NyA1eiBtMzMxIC0yNDggYzMgLTExMCAyIC0xMTMgLTE3IC0xMDMgLTExIDYKLTI4IDExIC0zOSAxMSAtMzggMCAtODQgMTA5IC02MyAxNDkgMTYgMjkgMzAgMjcgNDEgLTYgMjAgLTU2IDI1IC02MyAzOCAtNTUKOSA2IDEwIDIxIDMgNTcgLTEwIDU1IC03IDY4IDE3IDYzIDE0IC0zIDE3IC0yMCAyMCAtMTE2eiBtMTk5IDMxIGM2IC0xNiAtMzcKLTYzIC01OCAtNjMgLTIxIDAgLTIxIDMyIDEgNTYgMjcgMjggNDggMzEgNTcgN3ogbTI3MSAtODIgYzMgLTIxIDggLTIzIDM4Ci0xOCAyOSA1IDM1IDMgMzIgLTExIC0yIC0xMSAtMTUgLTE4IC0zOCAtMjAgLTUwIC01IC02MCAtMTkgLTMwIC00MiAxOSAtMTQKMjIgLTIyIDE0IC0zMCAtOSAtOSAtMjYgLTMgLTY4IDI0IC0zMSAyMCAtNTYgMzggLTU2IDQxIDAgMyAxMSAyNCAyNiA0NiAyMAozMyAzMCA0MCA1MiAzNyAyMCAtMiAyOCAtOSAzMCAtMjd6IG0tMTQ5OCAtOCBjMjMgLTMwIDIzIC02OCAwIC02OCAtOCAwIC0xNAo2IC0xMiAxNCA2IDI3IC05IDUxIC0zMiA1MSAtNTIgMCAtNzMgLTc1IC0yNCAtODIgMzEgLTQgMzUgLTI4IDUgLTI4IC0yOSAwCi02NyA0MSAtNjcgNzIgMCAxMCAxMSAzMCAyNSA0MyAzMyAzNCA3NyAzMyAxMDUgLTJ6IG0yNSAtMTM5IGMtMjcgLTI0IC01NAotNDMgLTU5IC00MSAtMjIgNyAtMTIgMjQgMzcgNjUgMzYgMzAgNTQgMzkgNjEgMzEgOCAtOCAtNCAtMjQgLTM5IC01NXogbTEzNjUKNjAgYzAgLTMgLTEyIC0yMCAtMjYgLTM2IC0xOCAtMjIgLTIyIC0zNCAtMTQgLTQyIDggLTggMTcgLTIgMzQgMTggMTQgMTkgMjcKMjYgMzUgMjIgOSAtNiA2IC0xNSAtMTMgLTM1IC0yMCAtMjEgLTIzIC0zMCAtMTQgLTM5IDkgLTkgMTkgLTUgNDQgMTkgNDYgNDQKNTMgMTkgOCAtMzAgLTQwIC00NSAtNDEgLTQ1IC0xMDMgMTIgbC00MiAzOCAzMyAzOSBjMjkgMzQgNTggNTEgNTggMzR6Cm0tMTI0NCAtODUgYzQxIC0zOSA1NCAtNTkgNTQgLTgwIDAgLTI3IDIgLTI4IDI3IC0xOCAyOSAxMSA1OCA1IDQ4IC0xMCAtMyAtNQotMjIgLTE1IC00MiAtMjIgLTIxIC03IC00NiAtMjMgLTU3IC0zNiAtMjYgLTMzIC00NiAtMTQgLTIyIDIxIDkgMTQgMTYgNDIgMTYKNjMgMCAzMiAtNSA0MCAtMjggNTEgLTI1IDEyIC0yOSAxMSAtNjQgLTI2IC0yNiAtMjkgLTM5IC0zNyAtNDcgLTI5IC04IDggMAoyMyAyOSA1MiAzNiAzNyAzOSA0MyAyNSA1NSAtOCA3IC0xNSAxNiAtMTUgMjEgMCAyMCAyNCA2IDc2IC00MnogbTExNzkgLTU0CmMzNSAtMzQgMzIgLTcwIC03IC0xMDYgLTE4IC0xNiAtMzYgLTI5IC0zOSAtMjkgLTQgMCAtMjYgMjMgLTQ5IDUyIGwtNDEgNTIKMzMgMjggYzQxIDM0IDcyIDM1IDEwMyAzeiBtLTE4NiAtMTAyIGM3IC0xNiAxOCAtMzYgMjYgLTQ2IDEyIC0xNyAxNSAtMTcgNDQKLTMgMzYgMTkgNDEgMjAgNDEgNCAwIC0xNSAtNzggLTYwIC05MSAtNTMgLTEzIDkgLTY3IDExNCAtNjEgMTIwIDEzIDEyIDMwIDMKNDEgLTIyeiBtLTczMCAtOCBjNDYgLTIzIDU1IC03NiAyMSAtMTEzIC0yNiAtMjggLTY5IC0yOCAtMTA0IC0xIC0zNCAyNyAtMzUKNzEgLTEgMTA0IDI4IDI5IDQ1IDMxIDg0IDEweiBtNjg0IC00OSBjMjMgLTY3IDUgLTk2IC01OSAtOTYgLTI1IDAgLTQ2IDI1Ci02NSA3OSAtOSAyNyAtOSAzNSAyIDQyIDExIDYgMTkgLTQgMzMgLTQxIDE1IC00MSAyMyAtNTAgNDIgLTUwIDI5IDAgMzEgMjMgOQo3NyAtMTIgMjkgLTEzIDM4IC0zIDQ0IDE3IDExIDIyIDMgNDEgLTU1eiBtLTUwMyAtMTIgYzAgLTExIC0xMCAtMTMgLTQwIC04Ci0zMiA1IC00MCAzIC00MCAtOCAwIC05IDEzIC0xOCAzMCAtMjEgNDMgLTkgMzkgLTMxIC00IC0yNCAtMzIgNSAtMzUgMyAtNDEKLTI0IC00IC0xNyAtMTIgLTI4IC0xOCAtMjYgLTEzIDUgLTEyIDUyIDMgMTA4IGwxMCAzNiA1MCAtMTAgYzMxIC02IDUwIC0xNQo1MCAtMjN6IG0zNDIgLTEgYzIzIC0yMCAyNCAtODAgMSAtMTA1IC0xNiAtMTggLTc3IC0yNSAtOTkgLTEwIC0xNCA5IC0zNCA0NwotMzQgNjUgMCA4IDkgMjYgMjEgNDEgMjQgMzEgODEgMzYgMTExIDl6IG0tMTU4IC05IGMxOSAtMTggMjAgLTMwIDYgLTM5IC04Ci01IC03IC0xMSAwIC0yMCA2IC04IDEwIC0yNCA4IC0zNyAtMyAtMjEgLTkgLTIzIC02NSAtMjYgbC02MyAtMyAwIDY0IGMwIDM1CjMgNjcgNyA3MCAxMyAxNCA5MiA3IDEwNyAtOXoiLz4KPHBhdGggZD0iTTE4MzAgNzEwIGMtMTEgLTIwIC02IC00MCA5IC00MCAxMSAwIDMxIDQ3IDI0IDU0IC0xMSAxMSAtMjIgNiAtMzMKLTE0eiIvPgo8cGF0aCBkPSJNMTYzMSA0ODcgYy04IC0xMCAtNCAtMjIgMTggLTQ3IDI1IC0zMCAzMSAtMzMgNDUgLTIxIDIxIDE4IDIwIDQ0Ci0yIDY0IC0yMiAyMCAtNDYgMjIgLTYxIDR6Ii8+CjxwYXRoIGQ9Ik03MzMgMzU0IGMtMjEgLTMzIC03IC01OSAzMyAtNTkgMjIgMCAzMSA2IDM4IDI3IDE5IDU0IC0zOSA4MCAtNzEKMzJ6Ii8+CjxwYXRoIGQ9Ik0xMjQ4IDMxOSBjLTI1IC0xNCAtMjQgLTY1IDIgLTc5IDQ1IC0yNCA4MiAzNyA0NCA3NCAtMTggMTkgLTIzIDE5Ci00NiA1eiIvPgo8cGF0aCBkPSJNMTA5MCAyOTUgYzAgLTkgOSAtMTUgMjUgLTE1IDE2IDAgMjUgNiAyNSAxNSAwIDkgLTkgMTUgLTI1IDE1IC0xNgowIC0yNSAtNiAtMjUgLTE1eiIvPgo8cGF0aCBkPSJNMTA5MCAyNDAgYzAgLTE3IDUgLTIxIDI4IC0xOCAxNiAyIDI3IDkgMjcgMTggMCA5IC0xMSAxNiAtMjcgMTgKLTIzIDMgLTI4IC0xIC0yOCAtMTh6Ii8+CjxwYXRoIGQ9Ik0yMTczIDExNTAgYzAgLTMwIDIgLTQzIDQgLTI3IDIgMTUgMiAzOSAwIDU1IC0yIDE1IC00IDIgLTQgLTI4eiIvPgo8cGF0aCBkPSJNMjE1NyAxMDE3IGMtNCAtNDAgLTE3IC0xMTEgLTMxIC0xNTcgLTEwNyAtMzY4IC0zOTMgLTY0OCAtNzY0IC03NDcKLTg2IC0yMyAtMTE2IC0yNiAtMjYyIC0yNiAtMTQ2IDAgLTE3NiAzIC0yNjIgMjYgLTEwNSAyOCAtMjMxIDgzIC0zMTkgMTM5Ci0yNDUgMTU3IC00MjIgNDI1IC00NzQgNzIwIC0xMyA3NSAtMTQgNzcgLTkgMjEgMTEgLTEzMSA4MyAtMzE5IDE3NCAtNDUzIDIwOAotMzA3IDU3NyAtNDg4IDk1MCAtNDY3IDQ1NyAyNiA4NDggMzQwIDk3NSA3ODIgMjMgODIgNDUgMjM1IDMzIDIzNSAtMyAwIC04Ci0zMyAtMTEgLTczeiIvPgo8L2c+Cjwvc3ZnPgo=";


function metadata(string calldata _name) external view returns(string memory){

    return string(abi.encodePacked('data:application/json;ascii,{"name": "',_name,'","description": "None-transferable boulder.eth sub-domain","image":"data:image/svg+xml;base64,', image, '"}'));
}



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Resolver_v1 is iResolver {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}