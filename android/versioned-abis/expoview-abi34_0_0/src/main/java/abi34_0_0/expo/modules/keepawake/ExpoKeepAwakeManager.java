package abi34_0_0.expo.modules.keepawake;

import android.app.Activity;
import android.view.WindowManager;

import abi34_0_0.org.unimodules.core.ModuleRegistry;
import abi34_0_0.org.unimodules.core.errors.CurrentActivityNotFoundException;
import abi34_0_0.org.unimodules.core.interfaces.ActivityProvider;
import abi34_0_0.org.unimodules.core.interfaces.InternalModule;
import abi34_0_0.org.unimodules.core.interfaces.services.KeepAwakeManager;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ExpoKeepAwakeManager implements KeepAwakeManager, InternalModule {

  private ModuleRegistry mModuleRegistry;
  private Set<String> mTags = new HashSet<>();

  @Override
  public void onCreate(ModuleRegistry moduleRegistry) {
    mModuleRegistry = moduleRegistry;
  }

  private Activity getCurrentActivity() throws CurrentActivityNotFoundException {
    ActivityProvider activityProvider = mModuleRegistry.getModule(ActivityProvider.class);
    if (activityProvider.getCurrentActivity() != null) {
      return activityProvider.getCurrentActivity();
    } else {
      throw new CurrentActivityNotFoundException();
    }
  }

  @Override
  public void activate(final String tag, final Runnable done) throws CurrentActivityNotFoundException {
    final Activity activity = getCurrentActivity();

    if (!isActivated()) {
      if (activity != null) {
        activity.runOnUiThread(() -> activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON));
      }
    }
    mTags.add(tag);
    done.run();
  }

  @Override
  public void deactivate(final String tag, final Runnable done) throws CurrentActivityNotFoundException {
    final Activity activity = getCurrentActivity();
    if (isActivated() && activity != null) {
      activity.runOnUiThread(() -> activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON));
    }
    mTags.remove(tag);
    done.run();
  }

  @Override
  public boolean isActivated() {
    return mTags.size() > 0;
  }

  @Override
  public List<? extends Class> getExportedInterfaces() {
    return Collections.singletonList(KeepAwakeManager.class);
  }
}
