// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WETH} from "solmate/src/tokens/WETH.sol";
import {LowLevelWETH} from "../../contracts/lowLevelCallers/LowLevelWETH.sol";
import {TestHelpers} from "./utils/TestHelpers.sol";

contract ImplementedLowLevelWETH is LowLevelWETH {
    function transferETH(
        address _WETH,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable {
        _transferETHAndWrapIfFailWithGasLimit(_WETH, _to, _amount, _gasLimit);
    }
}

abstract contract TestParameters {
    address internal _sender = address(100);
    uint256 internal _GAS_LIMIT = 10000;
}

contract RecipientFallback {
    ImplementedLowLevelWETH public lowLevelWETH;

    receive() external payable {
        // Infinite loop
        for (uint256 i; i < type(uint256).max; i++) {
            keccak256(abi.encode(i));
        }
    }
}

contract LowLevelWETHTest is TestParameters, TestHelpers {
    ImplementedLowLevelWETH public lowLevelWETH;
    RecipientFallback public recipientFallback;
    WETH public weth;

    function setUp() external {
        lowLevelWETH = new ImplementedLowLevelWETH();
        recipientFallback = new RecipientFallback();
        weth = new WETH();
    }

    function testTransferETH(uint256 amount) external payable asPrankedUser(_sender) {
        vm.deal(_sender, amount);
        lowLevelWETH.transferETH{value: amount}(address(weth), address(recipientFallback), amount, _GAS_LIMIT);
        assertEq(address(recipientFallback).balance, 0);
        assertEq(weth.balanceOf(address(recipientFallback)), amount);
    }
}
