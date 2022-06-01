// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/libraries/MarketLib.sol";
import "contracts/libraries/DigitalCertLib.sol";
import "contracts/IDigitalCert.sol";
import "contracts/IMarket.sol";

contract SuperXMulticall {

    IDigitalCert digitalCert;
    IMarket market;

    constructor(address digitalCertAddress, address marketAddress) {
        digitalCert = IDigitalCert(digitalCertAddress);
        market = IMarket(marketAddress);
    }

    function getRedeemByRedeemIdMulticall(uint256[] memory ids) public view returns(MarketLib.Redeemed[] memory) {
        MarketLib.Redeemed[] memory redeems = new MarketLib.Redeemed[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
             MarketLib.Redeemed memory redeem = market.getRedeemByRedeemId(ids[i]);
             redeems[i] = redeem;
        }
        return redeems;
    }

    function getRedeemByRedeemerAddress(address redeemer) public view returns (MarketLib.Redeemed[] memory) {
        uint256[] memory ids = market.getRedeemIdsByAddress(redeemer);
        MarketLib.Redeemed[] memory redeems = new MarketLib.Redeemed[](ids.length);
        if (ids.length <= 0) {
            return redeems;
        }
        redeems = getRedeemByRedeemIdMulticall(ids);
        return redeems;
    }

    function getDigitalCertificateById(uint256 id) public view returns(DigitalCertLib.DigitalCertificateRes memory) {
        DigitalCertLib.DigitalCertificateRes memory cert = digitalCert.getDigitalCertificate(id, address(market));
        cert.isPaused = market.isDigitalCertPaused(id);
        return cert;
    }

    function getDigitalCertificateByIdMulticall(uint256[] calldata ids) public view returns(DigitalCertLib.DigitalCertificateRes[] memory) {
        DigitalCertLib.DigitalCertificateRes[] memory certs = new  DigitalCertLib.DigitalCertificateRes[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
            DigitalCertLib.DigitalCertificateRes memory cert = getDigitalCertificateById(ids[i]);
            certs[i] = cert;
        }
        return certs;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MarketLib {
  struct Redeemed {
        uint256 redeemedId;
        address redeemer;
        uint256 certId;
        uint256 amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DigitalCertLib {
    struct DigitalCertificate {
      uint256 expire; // unix timestamp
      uint256 price;
    }

    struct DigitalCertificateRes {
      uint256 certId;
      uint256 expire;
      uint256 price;
      uint256 available;
      bool isPaused;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/libraries/DigitalCertLib.sol";

interface IDigitalCert {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function URI_SETTER_ROLE (  ) external view returns ( bytes32 );
  function balanceOf ( address account, uint256 id ) external view returns ( uint256 );
  function balanceOfBatch ( address[] memory accounts, uint256[] memory ids ) external view returns ( uint256[] memory );
  function burn ( address account, uint256 id, uint256 value ) external;
  function burnBatch ( address account, uint256[] memory ids, uint256[] memory values ) external;
  function createDigitalCert ( address account, uint256 amount, uint256 expire, uint256 price, bytes calldata data ) external;
  function createDigitalCertBatch ( address account, uint256[] calldata amounts, uint256[] calldata expires, uint256[] calldata prices, bytes calldata data ) external;
  function exists ( uint256 id ) external view returns ( bool );
  function getDigitalCertificate ( uint256 id, address marketAddress ) external view returns ( DigitalCertLib.DigitalCertificateRes memory );
  function getExpireDateById ( uint256 id ) external view returns ( uint256 );
  function getLastId (  ) external view returns ( uint256 );
  function getPriceById ( uint256 id ) external view returns ( uint256 );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isApprovedForAll ( address account, address operator ) external view returns ( bool );
  function mint ( address account, uint256 id, uint256 amount, bytes memory data ) external;
  function mintBatch ( address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function safeBatchTransferFrom ( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
  function safeTransferFrom ( address from, address to, uint256 id, uint256 amount, bytes memory data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setExpireDate ( uint256 id, uint256 expire ) external;
  function setPrice ( uint256 id, uint256 price ) external;
  function setURI ( string memory newuri ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function totalSupply ( uint256 id ) external view returns ( uint256 );
  function uri ( uint256 ) external view returns ( string memory );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/libraries/DigitalCertLib.sol";
import "contracts/libraries/MarketLib.sol";
interface IMarket {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function burnBatchFor ( uint256[] calldata certIds, uint256[] calldata burnAmounts ) external;
  function burnFor ( uint256 certId, uint256 burnAmount ) external;
  function getLastRedeemId (  ) external view returns ( uint256 );
  function getRedeemByRedeemId ( uint256 redeemId ) external view returns ( MarketLib.Redeemed memory );
  function getRedeemIdsByAddress ( address customer ) external view returns ( uint256[] memory );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isDigitalCertPaused ( uint256 certId ) external view returns ( bool );
  function onERC1155BatchReceived ( address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data ) external returns ( bytes4 );
  function onERC1155Received ( address operator, address from, uint256 id, uint256 value, bytes memory data ) external returns ( bytes4 );
  function onRedeem ( uint256 certId, uint256 amount ) external;
  function ownerAddress (  ) external view returns ( address );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setPauseForCertId ( uint256 certId, bool isPaused ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
}