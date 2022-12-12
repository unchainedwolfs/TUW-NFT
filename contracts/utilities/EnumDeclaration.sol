// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


enum Collection {
    RARE_WOLF,
    EPIC_WOLF,
    LEGENDARY_WOLF
}

struct Chest {
    uint256 Start;
    uint256 CurrentId;
    uint256 End;
    uint256 Cost;
    bool Status;
}