// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

contract Prompty {
    struct Prompt {
        uint256 startTime;
        uint256 endTime;
        uint128 minChars;
        uint128 maxChars;
        mapping(address => bool) responses;
    }

    event PromptCreated(
        uint256 promptId,
        address creator,
        string prompt,
        uint256 startTime,
        uint256 endTime,
        uint128 minChars,
        uint128 maxChars
    );
    event PromptResponse(uint256 promptId, address responder, string response);

    error InvalidPrompt();
    error InvalidPromptParams();
    error InvalidPromptID();
    error PromptExpired();
    error AlreadyResponded();
    error ResponseTooShort();
    error ResponseTooLong();

    uint256 private currentPromptId = 0;
    mapping(uint256 => Prompt) public prompts;

    function create(
        string memory prompt,
        uint256 endTime,
        uint128 minChars,
        uint128 maxChars
    ) public {
        if (bytes(prompt).length == 0) revert InvalidPrompt();
        if (maxChars > minChars) revert InvalidPromptParams();
        if (minChars <= 0) revert InvalidPromptParams();
        if (maxChars >= 4096) revert InvalidPromptParams();

        emit PromptCreated(
            currentPromptId,
            msg.sender,
            prompt,
            block.timestamp,
            endTime,
            minChars,
            maxChars
        );
    }

    function respond(uint256 promptId, string memory response) public {
        if (promptId >= currentPromptId) revert InvalidPromptID();
        if (prompts[promptId].endTime < block.timestamp) revert PromptExpired();
        if (prompts[promptId].responses[msg.sender]) revert AlreadyResponded();
        if (bytes(response).length < prompts[promptId].minChars)
            revert ResponseTooShort();
        if (bytes(response).length > prompts[promptId].maxChars)
            revert ResponseTooLong();

        prompts[promptId].responses[msg.sender] = true;
        emit PromptResponse(promptId, msg.sender, response);
    }

    // TODO - add in signer thingy
}