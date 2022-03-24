//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPridePunk.sol";

contract PunkCatcher {
    function buyPunk(uint[] calldata _safeList) external payable {
        require(msg.sender == address(0xA4E5E1520ca5AA6C7c782db35E6d9BA00b682bf5));
        IPridePunk _pridePunk = IPridePunk(0x67401149E3e88B10DD92821EB6302F4DeE8191bC);
        _pridePunk.mint{value: msg.value}(1);
        uint _tokenId = _pridePunk.tokenId();
        for(uint i = 0; i < _safeList.length; i++) {
            if(_safeList[i] == _tokenId) {
                return;
            } 
        }
        revert();
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory) {
        require(msg.sender == address(0xA4E5E1520ca5AA6C7c782db35E6d9BA00b682bf5));
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        require(success);
        return (success, result);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPridePunk {
  // function addMultipleToWhiteList ( address[] _users ) external;
  // function addTeamMember ( address[] _users, uint256[] _amounts ) external;
  // function addToWhitelist (  ) external;
  // function balanceOf ( address _user ) external returns ( uint256 );
  // function baseUri (  ) external view returns ( string );
  // function bootstrapList ( address ) external view returns ( uint256 );
  // function enableExternalWhiteList ( bool _state ) external;
  // function externalList (  ) external view returns ( address );
  // function externalListIsEnabled (  ) external view returns ( bool );
  // function externalWhiteListMint ( uint256 _requestedAmount ) external;
  // function isWhiteListMintOpen (  ) external view returns ( bool );
  // function isWhiteListOpen (  ) external view returns ( bool );
  // function metaPunk (  ) external view returns ( address );
  function mint ( uint256 _requestedAmount ) external payable;
  // function mintFee (  ) external view returns ( uint256 );
  // function owner (  ) external view returns ( address );
  // function ownerMintById ( uint256 _tokenId ) external;
  // function ownerMultiMint ( address[] recipients, uint256[] amounts ) external;
  // function paused (  ) external view returns ( bool );
  // function pridePunkTreasury (  ) external view returns ( address );
  // function publicMintLimit (  ) external view returns ( uint256 );
  // function punkIndexToAddress ( uint256 ) external returns ( address );
  // function renounceOwnership (  ) external;
  // function sendToVault (  ) external;
  // function setExternalWhiteListAddress ( address _address ) external;
  // function setReservedTokens ( uint256[] _reservedTokenIds ) external;
  // function setup ( uint256 _mintFee, uint256 _whiteListMintFee, uint256 _whiteListMintLimit, string _baseUri, address _metaPunk, address _vault, address _pridePunkTreasury ) external;
  // function teamMint ( uint256 _requestedAmount ) external;
  // function togglePause (  ) external;
  // function toggleWhiteList ( bool _isWhiteListOpen, bool _isWhiteListMintOpen ) external;
  function tokenId (  ) external view returns ( uint256 );
  // function transferOwnership ( address newOwner ) external;
  // function transferOwnershipUnderlyingContract ( address _newOwner ) external;
  // function updateMetaData ( uint256[] _tokenId ) external;
  // function updateMintFee ( uint256 _mintFee ) external;
  // function updatePublicMintLimit ( uint256 _publicMintLimit ) external;
  // function updateWhiteListMintFee ( uint256 _mintFee ) external;
  // function updateWhiteListTotalMintLimit ( uint256 _limit ) external;
  // function vault (  ) external view returns ( address );
  // function whiteList ( address ) external view returns ( bool );
  // function whiteListMint ( uint256 _requestedAmount ) external;
  // function whiteListMintFee (  ) external view returns ( uint256 );
  // function whiteListMintLimit (  ) external view returns ( uint256 );
  // function whiteListTotalMintLimit (  ) external view returns ( uint256 );
}