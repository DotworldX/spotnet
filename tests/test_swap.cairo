use ekubo::interfaces::core::IExtensionDispatcher;
use ekubo::interfaces::core::{SwapParameters};
use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use ekubo::types::i129::{i129};
use ekubo::types::keys::{PoolKey};

use snforge_std::cheatcodes::execution_info::caller_address::{
    start_cheat_caller_address, stop_cheat_caller_address
};
use snforge_std::{declare, DeclareResultTrait, ContractClassTrait};
use spotnet::constants::{EKUBO_CORE_MAINNET, EKUBO_CORE_SEPOLIA, ZKLEND_MARKET};
use spotnet::core::{ICoreDispatcher, ICoreDispatcherTrait};
use spotnet::types::{SwapData, DepositData};

use starknet::ContractAddress;

fn deploy_core(ekubo_core: felt252) -> IExtensionDispatcher {
    let contract = declare("Core").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(@array![ekubo_core, ZKLEND_MARKET])
        .expect('Deploy failed');

    IExtensionDispatcher { contract_address }
}

#[test]
#[fork("MAINNET")]
fn test_quote_for_base_mainnet() {
    let user: ContractAddress = 0x0038925b0bcf4dce081042ca26a96300d9e181b910328db54a6c89e5451503f5
        .try_into()
        .unwrap();
    let strk_addr: ContractAddress =
        0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();
    let eth_addr: ContractAddress =
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let swapper = deploy_core(EKUBO_CORE_MAINNET);
    let pool_key = PoolKey {
        token0: strk_addr,
        token1: eth_addr,
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0.try_into().unwrap()
    };
    let params = SwapParameters {
        amount: i129 { mag: 10000000000000, sign: false },
        is_token1: false,
        sqrt_ratio_limit: 18446748437148339061,
        skip_ahead: 0
    };
    let token_disp = IERC20Dispatcher {
        contract_address: if params.is_token1 {
            eth_addr
        } else {
            strk_addr
        }
    };
    let disp = IERC20Dispatcher { contract_address: strk_addr };
    println!("My bal ETH: {}", token_disp.balanceOf(user));
    println!("My bal STRK: {}", disp.balanceOf(user));
    start_cheat_caller_address(token_disp.contract_address, user);
    token_disp.approve(swapper.contract_address, params.amount.mag.into());
    stop_cheat_caller_address(token_disp.contract_address);
    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    let res = disp.swap(SwapData { params: params, pool_key, caller: user });
    assert(res.delta.amount0.mag == params.amount.mag, 'Amount not swapped');
}

#[test]
#[fork("MAINNET")]
fn test_both_directions_mainnet() {
    let user: ContractAddress = 0x0038925b0bcf4dce081042ca26a96300d9e181b910328db54a6c89e5451503f5
        .try_into()
        .unwrap();
    let usdc_addr: ContractAddress =
        0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8
        .try_into()
        .unwrap();
    let eth_addr: ContractAddress =
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let swapper = deploy_core(EKUBO_CORE_MAINNET);
    let pool_key = PoolKey {
        token0: eth_addr,
        token1: usdc_addr,
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0.try_into().unwrap()
    };
    let params = SwapParameters {
        amount: i129 { mag: 1000000, sign: false },
        is_token1: true,
        sqrt_ratio_limit: 6277100250585753475930931601400621808602321654880405518632,
        skip_ahead: 0
    };
    let token_disp = IERC20Dispatcher {
        contract_address: if params.is_token1 {
            usdc_addr
        } else {
            eth_addr
        }
    };
    let disp = IERC20Dispatcher { contract_address: eth_addr };
    println!("My bal USDC: {}", token_disp.balanceOf(user));
    println!("My bal ETH: {}", disp.balanceOf(user));
    start_cheat_caller_address(token_disp.contract_address, user);
    token_disp.approve(swapper.contract_address, params.amount.mag.into());
    stop_cheat_caller_address(token_disp.contract_address);
    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    let res = disp.swap(SwapData { params: params, pool_key, caller: user });
    println!("Swapped: {}", res.delta.amount0.mag);

    let params2 = SwapParameters {
        amount: i129 { mag: res.delta.amount0.mag, sign: false },
        is_token1: false,
        sqrt_ratio_limit: 18446748437148339061,
        skip_ahead: 0
    };

    let token_disp = IERC20Dispatcher {
        contract_address: if params2.is_token1 {
            usdc_addr
        } else {
            eth_addr
        }
    };
    let disp = IERC20Dispatcher { contract_address: usdc_addr };
    start_cheat_caller_address(token_disp.contract_address, user);
    token_disp.approve(swapper.contract_address, params2.amount.mag.into());
    stop_cheat_caller_address(token_disp.contract_address);
    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    let res = disp.swap(SwapData { params: params2, pool_key, caller: user });
    println!("My bal USDC: {}", IERC20Dispatcher { contract_address: usdc_addr }.balanceOf(user));
    println!("Swapped: {}", res.delta.amount0.mag);
}

#[test]
#[fork("SEPOLIA")]
fn test_quote_for_base_sepolia() {
    let strk_addr: ContractAddress =
        0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();
    let eth_addr: ContractAddress =
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let user = 0x06Cb0F3004Be46bcfc3d3030E08ebDDD64f13da663AD715FB4Aabe5423c7b862
        .try_into()
        .unwrap();

    let swapper = deploy_core(EKUBO_CORE_SEPOLIA);
    let pool_key = PoolKey {
        token0: strk_addr,
        token1: eth_addr,
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0.try_into().unwrap()
    };
    let params = SwapParameters {
        amount: i129 { mag: 10000000, sign: false },
        is_token1: false,
        sqrt_ratio_limit: 18446748437148339061,
        skip_ahead: 0
    };
    let token_disp = IERC20Dispatcher { contract_address: strk_addr };
    println!(
        "My bal SEPOLIA ETH before: {}",
        IERC20Dispatcher { contract_address: eth_addr }.balanceOf(user)
    );
    start_cheat_caller_address(token_disp.contract_address, user);
    token_disp.approve(swapper.contract_address, params.amount.mag.into());
    stop_cheat_caller_address(token_disp.contract_address);
    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    let res = disp.swap(SwapData { params: params, pool_key, caller: user });
    println!(
        "My bal SEPOLIA ETH after: {}",
        IERC20Dispatcher { contract_address: eth_addr }.balanceOf(user)
    );
    println!("Swapped: {}", res.delta.amount1.mag);
}

#[test]
#[fork("SEPOLIA")]
fn test_base_for_quote_sepolia() {
    let strk_addr: ContractAddress =
        0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();
    let eth_addr: ContractAddress =
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let user = 0x06Cb0F3004Be46bcfc3d3030E08ebDDD64f13da663AD715FB4Aabe5423c7b862
        .try_into()
        .unwrap();

    let swapper = deploy_core(EKUBO_CORE_SEPOLIA);
    let pool_key = PoolKey {
        token0: strk_addr,
        token1: eth_addr,
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0.try_into().unwrap()
    };
    let params = SwapParameters {
        amount: i129 { mag: 10000000, sign: false },
        is_token1: true,
        sqrt_ratio_limit: 6277100250585753475930931601400621808602321654880405518632,
        skip_ahead: 0
    };
    let token_disp = IERC20Dispatcher { contract_address: eth_addr };
    println!(
        "My bal SEPOLIA ETH before: {}",
        IERC20Dispatcher { contract_address: eth_addr }.balanceOf(user)
    );
    start_cheat_caller_address(token_disp.contract_address, user);
    token_disp.approve(swapper.contract_address, params.amount.mag.into());
    stop_cheat_caller_address(token_disp.contract_address);
    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    let res = disp.swap(SwapData { params: params, pool_key, caller: user });
    println!(
        "My bal SEPOLIA ETH after: {}",
        IERC20Dispatcher { contract_address: eth_addr }.balanceOf(user)
    );
    println!("Swapped: {}", res.delta.amount0.mag);
}

#[test]
#[fork("MAINNET")]
fn test_loop_base_token_zklend() {
    let usdc_addr: ContractAddress =
        0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8
        .try_into()
        .unwrap();
    let eth_addr: ContractAddress =
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let user = 0x0038925b0bcf4dce081042ca26a96300d9e181b910328db54a6c89e5451503f5
        .try_into()
        .unwrap();

    let swapper = deploy_core(EKUBO_CORE_MAINNET);
    let pool_key = PoolKey {
        token0: eth_addr,
        token1: usdc_addr,
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0.try_into().unwrap()
    };
    let pool_price = 2550000000;
    let token_disp = IERC20Dispatcher { contract_address: eth_addr };

    //// 1
    ////Dep: 1000000000000000
    ////Acc: 1344460028370827
    // start_cheat_caller_address(eth_addr.try_into().unwrap(), user);
    // token_disp.approve(swapper.contract_address, 1000000000000000);
    // stop_cheat_caller_address(eth_addr);

    // println!("Balance state pre: {}", token_disp.balanceOf(user));
    // let disp = ICoreDispatcher {contract_address: swapper.contract_address};
    // disp.loop_liquidity(eth_addr, 1000000000000000, 10, pool_key, user);

    //// 2
    ////Dep: 38500000000000000 (100$)
    ////Acc: 140844817938389045
    // println!("Balance state after: {}", token_disp.balanceOf(user));
    // start_cheat_caller_address(eth_addr.try_into().unwrap(), user);
    // token_disp.approve(swapper.contract_address, 38500000000000000);
    // stop_cheat_caller_address(eth_addr);

    // println!("Balance state pre: {}", token_disp.balanceOf(user));
    // let disp = ICoreDispatcher {contract_address: swapper.contract_address};
    // disp.loop_liquidity(eth_addr, 38500000000000000, 27, pool_key, user);

    //// 3
    ////Dep: 385000000000000000 (1000$)
    ////Acc: 1450806999280433352
    start_cheat_caller_address(eth_addr.try_into().unwrap(), user);
    token_disp.approve(swapper.contract_address, 385000000000000000);
    stop_cheat_caller_address(eth_addr);
    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    disp
        .loop_liquidity(
            DepositData {
                token: eth_addr, amount: 385000000000000000, multiplier: 4
            }, // For now multiplier is a number of iterations
            pool_key,
            pool_price,
            user
        );
}

#[test]
#[fork("MAINNET")]
fn test_loop_quote_token_zklend() {
    let usdc_addr: ContractAddress =
        0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8
        .try_into()
        .unwrap();
    let eth_addr: ContractAddress =
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let user = 0x0038925b0bcf4dce081042ca26a96300d9e181b910328db54a6c89e5451503f5
        .try_into()
        .unwrap();

    let swapper = deploy_core(EKUBO_CORE_MAINNET);
    let pool_key = PoolKey {
        token0: eth_addr,
        token1: usdc_addr,
        fee: 170141183460469235273462165868118016,
        tick_spacing: 1000,
        extension: 0.try_into().unwrap()
    };
    let pool_price = 370000000000000;
    let token_disp = IERC20Dispatcher { contract_address: usdc_addr };

    start_cheat_caller_address(usdc_addr.try_into().unwrap(), user);
    token_disp.approve(swapper.contract_address, 10000000);
    stop_cheat_caller_address(usdc_addr);

    let disp = ICoreDispatcher { contract_address: swapper.contract_address };
    disp
        .loop_liquidity(
            DepositData {
                token: usdc_addr, amount: 10000000, multiplier: 4
            }, // For now multiplier is a number of iterations
            pool_key,
            pool_price,
            user
        );
}
//// Investigate looping through STRK and other tokens
// #[test]
// #[fork("MAINNET")]
// fn test_loop_eth_strk_token_zklend() {
//     let strk_addr: ContractAddress =
//         0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
//         .try_into()
//         .unwrap();
//     let eth_addr: ContractAddress =
//         0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
//         .try_into()
//         .unwrap();
//     let user = 0x0038925b0bcf4dce081042ca26a96300d9e181b910328db54a6c89e5451503f5
//         .try_into()
//         .unwrap();

//     let swapper = deploy_core(EKUBO_CORE_MAINNET);
//     let pool_key = PoolKey {
//         token0: strk_addr,
//         token1: eth_addr,
//         fee: 0x28f5c28f5c28f5c28f5c28f5c28f5c2,
//         tick_spacing: 19802,
//         extension: 0.try_into().unwrap()
//     };
//     let pool_price = 6000000000000000000000;
//     let token_disp = IERC20Dispatcher { contract_address: eth_addr };
//     // 41600000000000000000
//     // 84674241142648157000
//     start_cheat_caller_address(eth_addr.try_into().unwrap(), user);
//     token_disp.approve(swapper.contract_address, 10000000000000000);
//     stop_cheat_caller_address(eth_addr);

//     let disp = ICoreDispatcher { contract_address: swapper.contract_address };
//     disp
//         .loop_liquidity(
//             DepositData {
//                 token: eth_addr, amount: 10000000000000000, multiplier: 3
//             }, // For now multiplier is a number of iterations
//             pool_key,
//             pool_price,
//             user
//         );
// }

