// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../interfaces/IRenderer.sol";

contract RendererRegistry {

    mapping(uint => address) public idToAddress;
    mapping(address => uint) public addressToId;

    uint public idCounter = 0;

    constructor (
    ) {
    } 

    event RegisteredRenderer(
      uint id,
      address renderer,
      uint propsSize,
      string additionalMetadataURI
    );

    function registerRenderer(address _renderer) public {
      idCounter++;
      IRenderer renderer = IRenderer(_renderer);
      require(renderer.supportsInterface(type(IRenderer).interfaceId), "Does not abide to IRenderer spec");
      require(addressToId[_renderer] == 0, "Already registered");
      idToAddress[idCounter] = _renderer;
      addressToId[_renderer] = idCounter;
      emit RegisteredRenderer(idCounter, _renderer, renderer.propsSize(), renderer.additionalMetadataURI());
    }

    function editRenderer(address _oldRenderer, address _renderer) public {
      IRenderer oldRenderer = IRenderer(_oldRenderer);
      require(oldRenderer.owner() == msg.sender, "Not owner of old renderer");
      IRenderer renderer = IRenderer(_renderer);
      uint rendererId = addressToId[_oldRenderer]; 
      require(rendererId != 0, "Old renderer not registered.");
      require(addressToId[_renderer] == 0, "New renderer already registered");
      require(renderer.supportsInterface(type(IRenderer).interfaceId), "Does not abide to IRenderer spec");
      idToAddress[rendererId] = _renderer;
      addressToId[_renderer] = rendererId;
      emit RegisteredRenderer(rendererId, _renderer, renderer.propsSize(), renderer.additionalMetadataURI());
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IRenderer is IERC165 {
  function owner() external view returns (address);
  function propsSize() external pure returns (uint256);
  function additionalMetadataURI() external pure returns (string memory);
  function renderAttributeKey() external pure returns (string memory);
  function renderRaw(bytes calldata props) external view returns (string memory);
  function render(bytes calldata props) external view returns (string memory);
  function attributes(bytes calldata props) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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