from vyper.interfaces import ERC721


@external
def __init__():
    pass


@external
def massRetrieveERC721(token: ERC721, receiver: address, tokenIds: uint256[1000]):
    for tokenId in tokenIds:
        token.transferFrom(msg.sender, receiver, tokenId)