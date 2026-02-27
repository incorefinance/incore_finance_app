-- Add updated_at auto-update triggers for tables that have the column but no trigger.
-- Tables: usage_metrics, device_tokens, user_notification_preferences

-- ============================================================================
-- 1. usage_metrics
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_usage_metrics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usage_metrics_updated_at
  BEFORE UPDATE ON public.usage_metrics
  FOR EACH ROW
  EXECUTE FUNCTION public.update_usage_metrics_updated_at();

-- ============================================================================
-- 2. device_tokens
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.update_device_tokens_updated_at();

-- ============================================================================
-- 3. user_notification_preferences
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_user_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_notification_preferences_updated_at
  BEFORE UPDATE ON public.user_notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.update_user_notification_preferences_updated_at();
