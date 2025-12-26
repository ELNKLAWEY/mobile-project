import { cn } from '@/lib/utils';

type Status = 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';

interface StatusBadgeProps {
  status: Status;
}

const statusConfig: Record<Status, { label: string; className: string }> = {
  pending: {
    label: 'Pending',
    className: 'bg-warning/10 text-warning border-warning/20',
  },
  processing: {
    label: 'Processing',
    className: 'bg-primary/10 text-primary border-primary/20',
  },
  shipped: {
    label: 'Shipped',
    className: 'bg-primary/10 text-primary border-primary/20',
  },
  delivered: {
    label: 'Delivered',
    className: 'bg-success/10 text-success border-success/20',
  },
  cancelled: {
    label: 'Cancelled',
    className: 'bg-destructive/10 text-destructive border-destructive/20',
  },
};

const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const config = statusConfig[status] || statusConfig.pending;

  return (
    <span
      className={cn(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border',
        config.className
      )}
    >
      {config.label}
    </span>
  );
};

export default StatusBadge;
