lua ../../amalg.lua -s init.lua -o dist_unminified.lua -- \
    item \
    util \
    config \
    state \
    state.inventory \
    state.movement \
    state.machine \
    state.machine.states \
    net \
    net.packet
echo "Amalgamation complete"
lua ../../minifier.lua dist_unminified.lua dist.lua
echo "Done building"
