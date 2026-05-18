package com.wycklops.protoware;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(AgeSignalPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
